mod bumps;
mod cdx;
mod deps;
mod mail;
mod scan;
mod trend;

use anyhow::{Context, Result, bail};
use clap::{Args, Parser, Subcommand};
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Parser)]
#[command(
    version,
    about = "CVE and version-bump audit for NixOS system closures"
)]
struct Cli {
    #[command(subcommand)]
    command: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Scan host closures for known vulnerabilities
    Scan(ScanArgs),
    /// Compare watchlist package versions between two revisions
    Bumps(BumpsArgs),
    /// Run both and mail the daily delta, or print it without SMTP configured
    Report(ReportArgs),
}

#[derive(Args, Clone, Default)]
pub struct ScanArgs {
    /// Hosts to scan (default: this machine's hostname)
    pub hosts: Vec<String>,
    /// Scan buildtime dependencies, which needs no realized closure
    #[arg(long)]
    pub buildtime: bool,
    /// Skip the repology-backed triage columns
    #[arg(long)]
    pub no_triage: bool,
    /// Scan this store path instead of a host toplevel
    #[arg(long)]
    pub target: Option<String>,
    /// Directory to keep the raw vulnxscan CSVs in
    #[arg(long)]
    pub out: Option<PathBuf>,
    /// Whitelist CSV (default: $NIX_AUDIT_WHITELIST)
    #[arg(long)]
    pub whitelist: Option<PathBuf>,
    /// Exit non-zero when a finding of this severity remains
    #[arg(long, value_name = "SEVERITY")]
    pub fail_on: Option<String>,
    /// Write a CycloneDX SBOM with all findings per host into this directory
    #[arg(long, value_name = "DIR")]
    pub cdx: Option<PathBuf>,
    #[arg(skip)]
    pub quiet: bool,
}

#[derive(Args, Clone)]
pub struct BumpsArgs {
    #[arg(long, default_value = "HEAD~1")]
    pub from: String,
    /// Revision to compare against (default: the working tree)
    #[arg(long)]
    pub to: Option<String>,
    #[arg(long, default_value = "loptland")]
    pub host: String,
    /// Also diff the two realized toplevels with nvd
    #[arg(long)]
    pub all: bool,
}

#[derive(Args)]
pub struct ReportArgs {
    /// Hosts to scan (default: this machine's hostname)
    pub hosts: Vec<String>,
    /// Revision to compare against (default: the commit of the last audit, else HEAD~1)
    #[arg(long)]
    pub from: Option<String>,
    /// Host whose package set the version comparison evaluates
    #[arg(long, default_value = "loptland")]
    pub host: String,
    /// Scan this store path instead of host toplevels, skipping the version comparison
    #[arg(long)]
    pub target: Option<String>,
    /// Write a CycloneDX SBOM with all findings per host into this directory
    #[arg(long, value_name = "DIR")]
    pub cdx: Option<PathBuf>,
    /// Name of this audit, keeping its state and mail apart from other audits
    #[arg(long, env = "NIX_AUDIT_SCOPE", default_value = "hosts")]
    pub scope: String,
    /// Trend state file (default: $XDG_STATE_HOME/nix-audit/<scope>.json)
    #[arg(long, env = "NIX_AUDIT_STATE")]
    pub state: Option<PathBuf>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let root = repo_root()?;

    match cli.command {
        Cmd::Scan(args) => {
            let mut findings = scan::run(&root, &args)?;
            cdx::write(args.cdx.as_deref(), &mut findings);
            print!("{}", scan::markdown(&findings));
            if let Some(severity) = &args.fail_on {
                let hits = scan::count_at_least(&findings, severity)?;
                if hits > 0 {
                    bail!("{hits} findings at severity {severity} or above");
                }
            }
        }
        Cmd::Bumps(args) => {
            let bumps = bumps::run(&root, &args)?;
            print!("{}", bumps::markdown(&bumps));
        }
        Cmd::Report(args) => report(&root, &args)?,
    }
    Ok(())
}

fn report(root: &Path, args: &ReportArgs) -> Result<()> {
    let path = match &args.state {
        Some(path) => path.clone(),
        None => trend::default_path(&args.scope)?,
    };
    let mut state = trend::State::load(&path)?;
    let mail = mail::Config::from_env();
    let today = today()?;

    // Comparing from the last audited commit covers everything merged since the previous mail.
    let from = args
        .from
        .clone()
        .or_else(|| state.since(&today).map(String::from))
        .unwrap_or_else(|| String::from("HEAD~1"));
    // A bare store path has no host config behind it, so there is nothing to diff.
    let bumps = args.target.is_none().then(|| {
        bumps::run(
            root,
            &BumpsArgs {
                from,
                to: None,
                host: args.host.clone(),
                all: false,
            },
        )
        .inspect_err(|e| eprintln!("warning: version comparison skipped: {e:#}"))
        .ok()
    });
    let bumps = bumps.flatten();
    let mut findings = scan::run(
        root,
        &ScanArgs {
            hosts: args.hosts.clone(),
            target: args.target.clone(),
            quiet: mail.is_some(),
            ..Default::default()
        },
    )?;
    cdx::write(args.cdx.as_deref(), &mut findings);

    let hash = git(root, &["rev-parse", "HEAD"])?;
    let short = trend::short(&hash);
    let diff = state.advance(&hash, &today, &findings);

    let open: usize = findings.iter().map(|f| f.rows.len()).sum();
    let bumped = bumps.as_ref().map_or(0, |b| b.changes.len());
    let change = diff
        .as_ref()
        .map_or_else(|| String::from("first run"), trend::Diff::summary);
    let subject = format!("nix-audit {}: {change}, {open} open", args.scope);

    let web = web_url();
    let mut body = format!(
        "# {subject}\n\nAudit of [`{short}`]({web}/commit/{hash}) on {today}: {open} high or critical findings across {} host(s), {bumped} watchlist bump(s).\n\n",
        findings.len()
    );
    if let Some(diff) = &diff {
        let since = &diff.since;
        let compare = if since == &hash {
            String::new()
        } else {
            format!(", [compare]({web}/compare/{since}...{hash})")
        };
        body.push_str(&format!(
            "## Since {} ([`{}`]({web}/commit/{since}){compare})\n\n{}",
            diff.since_date,
            trend::short(since),
            diff.markdown(&findings)
        ));
    }
    if let Some(bumps) = bumps.as_ref().filter(|b| !b.changes.is_empty()) {
        body.push_str(&bumps::markdown(bumps));
    }
    body.push_str(&format!("---\n\n{}", scan::markdown(&findings)));

    let graphs: Vec<(String, String)> = findings
        .iter()
        .filter_map(|f| Some((format!("trend-{}.svg", f.host), state.svg(&f.host)?)))
        .collect();

    match &mail {
        Some(config) => {
            mail::send(config, &subject, &body, &graphs)?;
            println!(
                "mailed {} report to {}: {change}, {open} open",
                args.scope, config.to
            );
        }
        None => print!("{body}"),
    }
    // Saved only once the mail is out, so a failed send widens the next delta instead of losing it.
    state.save(&path)
}

fn web_url() -> String {
    let env = |key| std::env::var(key).ok().filter(|v: &String| !v.is_empty());
    match (env("GITHUB_SERVER_URL"), env("GITHUB_REPOSITORY")) {
        (Some(server), Some(repo)) => format!("{}/{repo}", server.trim_end_matches('/')),
        _ => String::from("https://git.christophhollizeck.dev/Daholli/nixos-config"),
    }
}

fn today() -> Result<String> {
    let out = Command::new("date")
        .arg("+%F")
        .output()
        .context("running date")?;
    Ok(String::from_utf8(out.stdout)?.trim().to_string())
}

pub fn git(root: &Path, args: &[&str]) -> Result<String> {
    let out = Command::new("git")
        .current_dir(root)
        .args(args)
        .output()
        .context("running git")?;
    if !out.status.success() {
        bail!(
            "git {} failed: {}",
            args.join(" "),
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(String::from_utf8(out.stdout)?.trim().to_string())
}

fn repo_root() -> Result<PathBuf> {
    let cwd = std::env::current_dir()?;
    Ok(PathBuf::from(git(&cwd, &["rev-parse", "--show-toplevel"])?))
}

pub fn table(headers: &[&str], rows: &[Vec<String>]) -> String {
    let mut out = format!("| {} |\n", headers.join(" | "));
    out.push_str(&format!("|{}\n", " --- |".repeat(headers.len())));
    for row in rows {
        out.push_str(&format!("| {} |\n", row.join(" | ")));
    }
    out
}
