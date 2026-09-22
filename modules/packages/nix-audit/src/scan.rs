use crate::{ScanArgs, table};
use anyhow::{Context, Result, bail};
use std::collections::BTreeMap;
use std::io::{BufRead, BufReader, stderr};
use std::os::fd::AsFd;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

pub type Row = BTreeMap<String, String>;

pub struct HostFindings {
    pub host: String,
    pub rows: Vec<Row>,
    pub below: Vec<Row>,
    pub suppressed: usize,
}

const EXPECTED: [&str; 5] = ["vuln_id", "url", "package", "severity", "sum"];
const SEVERITIES: [&str; 5] = ["negligible", "low", "medium", "high", "critical"];
const FLOOR: &str = "high";

pub fn run(root: &Path, args: &ScanArgs) -> Result<Vec<HostFindings>> {
    let out = match &args.out {
        Some(dir) => dir.clone(),
        None => std::env::temp_dir().join(format!("nix-audit-{}", std::process::id())),
    };
    std::fs::create_dir_all(&out)?;

    let whitelist = args
        .whitelist
        .clone()
        .or_else(|| std::env::var_os("NIX_AUDIT_WHITELIST").map(PathBuf::from));

    let mut findings = Vec::new();
    let mut triage = !args.no_triage;
    for (name, target) in targets(root, args)? {
        let csv = out.join(format!("{name}.csv"));
        let (mut ok, errors) = vulnxscan(&out, args, &whitelist, &csv, &target, triage)?;
        // --triage resolves upstream versions through repology.org, so an outage there fails
        // a scan whose findings do not need it. Each retry costs a second closure evaluation,
        // so only a repology failure earns one, and only for the first host: the rest of the
        // run would fail identically.
        if !ok && triage && errors.contains("repology") {
            eprintln!("warning: repology is unreachable, rescanning {name} without --triage");
            triage = false;
            ok = vulnxscan(&out, args, &whitelist, &csv, &target, false)?.0;
        }
        if !ok {
            bail!("vulnxscan failed for {name}");
        }
        let graph = realized(&errors, args).and_then(|p| crate::deps::Graph::load(&p).ok());
        findings.push(collect(name, &csv, graph.as_ref())?);
    }
    Ok(findings)
}

fn vulnxscan(
    cwd: &Path,
    args: &ScanArgs,
    whitelist: &Option<PathBuf>,
    csv: &Path,
    target: &str,
    triage: bool,
) -> Result<(bool, String)> {
    let mut cmd = Command::new("vulnxscan");
    cmd.current_dir(cwd).arg("--out").arg(csv);
    if triage {
        cmd.arg("--triage");
    }
    if args.buildtime {
        cmd.arg("--buildtime");
    }
    if let Some(path) = whitelist {
        cmd.arg("--whitelist").arg(path);
    }
    cmd.arg(target);
    // vulnxscan writes its own report to stdout; ours has to stay pure markdown.
    cmd.stdout(Stdio::from(stderr().as_fd().try_clone_to_owned()?));
    cmd.stderr(Stdio::piped());

    let mut child = cmd.spawn().context("running vulnxscan")?;
    let mut errors = String::new();
    if let Some(pipe) = child.stderr.take() {
        for line in BufReader::new(pipe).lines() {
            let line = line?;
            eprintln!("{line}");
            errors.push_str(&line);
            errors.push('\n');
        }
    }
    Ok((child.wait()?.success(), errors))
}

fn targets(root: &Path, args: &ScanArgs) -> Result<Vec<(String, String)>> {
    if let Some(path) = &args.target {
        // A store path carries no nixpkgs metadata, so vulnxscan cannot enrich the triage
        // columns the way it does for a flake ref.
        return Ok(vec![(String::from("target"), path.clone())]);
    }
    let hosts = if args.hosts.is_empty() {
        vec![
            std::fs::read_to_string("/etc/hostname")
                .context("reading /etc/hostname; pass hosts explicitly")?
                .trim()
                .to_string(),
        ]
    } else {
        args.hosts.clone()
    };
    Ok(hosts
        .into_iter()
        .map(|host| {
            let target = format!(
                "{}#nixosConfigurations.{host}.config.system.build.toplevel",
                root.display()
            );
            (host, target)
        })
        .collect())
}

fn realized(errors: &str, args: &ScanArgs) -> Option<String> {
    if let Some(path) = &args.target {
        return Some(path.clone());
    }
    let marker = "Generating SBOM for target '";
    let start = errors.find(marker)? + marker.len();
    let rest = &errors[start..];
    Some(rest[..rest.find('\'')?].to_string())
}

fn collect(host: String, csv: &Path, graph: Option<&crate::deps::Graph>) -> Result<HostFindings> {
    let mut reader = csv::ReaderBuilder::new().flexible(true).from_path(csv)?;
    let headers = reader.headers()?.clone();
    for column in EXPECTED {
        if !headers.iter().any(|h| h == column) {
            eprintln!("warning: vulnxscan report has no `{column}` column");
        }
    }

    let mut rows = Vec::new();
    let mut below = Vec::new();
    let mut suppressed = 0;
    for record in reader.records() {
        let record = record?;
        let mut row: Row = headers
            .iter()
            .map(String::from)
            .zip(record.iter().map(String::from))
            .collect();
        if let Some(graph) = graph {
            let key = format!("{}-{}", field(&row, "package"), version(&row));
            if let Some(via) = graph.introducer(&key) {
                row.insert(String::from("via"), via);
            }
        }
        if truthy(field(&row, "whitelist")) {
            suppressed += 1;
        } else if rank(field(&row, "severity")) >= rank(FLOOR) {
            rows.push(row);
        } else {
            below.push(row);
        }
    }
    rows.sort_by(|a, b| {
        rank(field(b, "severity"))
            .cmp(&rank(field(a, "severity")))
            .then(scanners(b).cmp(&scanners(a)))
            .then(field(a, "vuln_id").cmp(field(b, "vuln_id")))
    });

    Ok(HostFindings {
        host,
        rows,
        below,
        suppressed,
    })
}

pub fn markdown(findings: &[HostFindings]) -> String {
    let mut out = String::new();
    for host in findings {
        out.push_str(&format!("## Vulnerabilities — {}\n\n", host.host));
        if host.rows.is_empty() {
            out.push_str("No high or critical findings.\n\n");
        } else {
            let rows: Vec<Vec<String>> = host
                .rows
                .iter()
                .map(|r| {
                    vec![
                        severity_label(r),
                        format!("[{}]({})", field(r, "vuln_id"), field(r, "url")),
                        field(r, "package").to_string(),
                        version(r).to_string(),
                        field(r, "classify").to_string(),
                        field(r, "via").to_string(),
                        field(r, "whitelist_comment").to_string(),
                    ]
                })
                .collect();
            out.push_str(&table(
                &[
                    "Severity", "ID", "Package", "Version", "Triage", "Via", "Note",
                ],
                &rows,
            ));
            out.push('\n');
        }
        out.push_str(&format!(
            "_{} finding(s) below {}, {} whitelisted._\n\n",
            host.below.len(),
            FLOOR,
            host.suppressed
        ));
    }
    out
}

pub fn count_at_least(findings: &[HostFindings], severity: &str) -> Result<usize> {
    let floor = rank(severity);
    if floor == 0 {
        bail!("unknown severity `{severity}`, expected one of {SEVERITIES:?}");
    }
    Ok(findings
        .iter()
        .flat_map(|f| f.rows.iter().chain(f.below.iter()))
        .filter(|r| rank(field(r, "severity")) >= floor)
        .count())
}

pub fn field<'a>(row: &'a Row, key: &str) -> &'a str {
    row.get(key).map(String::as_str).unwrap_or_default()
}

pub fn version(row: &Row) -> &str {
    let local = field(row, "version_local");
    if local.is_empty() {
        field(row, "version")
    } else {
        local
    }
}

fn scanners(row: &Row) -> u32 {
    field(row, "sum").trim().parse().unwrap_or(0)
}

// vulnxscan reports severity as a CVSS base score rather than the name its docs suggest,
// so accept both and band the score the way the CVSS v3 specification does.
fn rank(severity: &str) -> usize {
    let severity = severity.trim().to_ascii_lowercase();
    if let Ok(score) = severity.parse::<f64>() {
        return match score {
            s if s >= 9.0 => 5,
            s if s >= 7.0 => 4,
            s if s >= 4.0 => 3,
            s if s > 0.0 => 2,
            _ => 1,
        };
    }
    SEVERITIES
        .iter()
        .position(|s| *s == severity)
        .map_or(0, |i| i + 1)
}

fn truthy(value: &str) -> bool {
    matches!(value.trim().to_ascii_lowercase().as_str(), "true" | "1")
}

fn severity_label(row: &Row) -> String {
    let raw = field(row, "severity");
    match rank(raw).checked_sub(1).and_then(|i| SEVERITIES.get(i)) {
        Some(name) if *name != raw => format!("{name} ({raw})"),
        _ => raw.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ranks_cvss_scores_and_names() {
        assert_eq!(rank("9.8"), rank("critical"));
        assert_eq!(rank("7.5"), rank("high"));
        assert_eq!(rank("6.5"), rank("medium"));
        assert!(rank("7.0") >= rank(FLOOR));
        assert!(rank("6.9") < rank(FLOOR));
        assert_eq!(rank("nonsense"), 0);
    }
}
