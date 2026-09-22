mod bumps;
mod forgejo;
mod scan;

use anyhow::{Context, Result, bail};
use clap::{Args, Parser, Subcommand};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::process::Command;

const ISSUE_TITLE: &str = "nix-audit: open vulnerabilities";

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
    /// Run both and upsert the Forgejo tracking issue
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
    #[arg(long, default_value = "HEAD~1")]
    pub from: String,
    /// Host whose package set the version comparison evaluates
    #[arg(long, default_value = "loptland")]
    pub host: String,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let root = repo_root()?;

    match cli.command {
        Cmd::Scan(args) => {
            let findings = scan::run(&root, &args)?;
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
    let bumps = bumps::run(
        root,
        &BumpsArgs {
            from: args.from.clone(),
            to: None,
            host: args.host.clone(),
            all: false,
        },
    )
    .inspect_err(|e| eprintln!("warning: version comparison skipped: {e:#}"))
    .ok();
    let findings = scan::run(
        root,
        &ScanArgs {
            hosts: args.hosts.clone(),
            ..Default::default()
        },
    )?;

    let reported: usize = findings.iter().map(|f| f.rows.len()).sum();
    let bumped = bumps.as_ref().map_or(0, |b| b.changes.len());
    let fingerprint = fingerprint(&findings);
    let body = format!(
        "{}\n{}{}\n<!-- fingerprint: {} -->\n",
        preamble(root)?,
        scan::markdown(&findings),
        bumps.as_ref().map(bumps::markdown).unwrap_or_default(),
        fingerprint
    );
    print!("{body}");

    let token = std::env::var("FORGEJO_TOKEN").unwrap_or_default();
    if token.is_empty() {
        return Ok(());
    }
    let comment = format!(
        "Report updated: {reported} high or critical findings across {} host(s), {bumped} watchlist bump(s).",
        findings.len()
    );
    // The report above is the deliverable; posting it is best-effort, so a missing issue
    // scope on the token must not discard a scan that took half an hour.
    match forgejo::upsert(
        &forgejo::Config::from_env(),
        &token,
        ISSUE_TITLE,
        &body,
        &fingerprint,
        &comment,
        bumped > 0,
    ) {
        Ok(action) => eprintln!("forgejo: {action}"),
        Err(error) => eprintln!("warning: tracking issue not updated: {error:#}"),
    }
    Ok(())
}

fn preamble(root: &Path) -> Result<String> {
    let commit = git(root, &["log", "-1", "--format=%h %cs"])?;
    Ok(format!("# {ISSUE_TITLE}\n\nAs of commit {commit}.\n"))
}

fn fingerprint(findings: &[scan::HostFindings]) -> String {
    let mut lines: Vec<String> = findings
        .iter()
        .flat_map(|f| {
            f.rows.iter().map(move |r| {
                format!(
                    "{},{},{},{}",
                    f.host,
                    scan::field(r, "vuln_id"),
                    scan::field(r, "package"),
                    scan::version(r)
                )
            })
        })
        .collect();
    lines.sort();
    let mut hasher = Sha256::new();
    hasher.update(lines.join("\n"));
    format!("{:x}", hasher.finalize())
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
