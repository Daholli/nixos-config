use crate::scan::{self, HostFindings, field};
use crate::table;
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

const KEEP: usize = 30;

/// Carried between runs in a state file on the machine that runs the audit.
#[derive(Default, Serialize, Deserialize)]
pub struct State {
    history: Vec<Point>,
    findings: BTreeSet<String>,
    #[serde(default)]
    last: Option<Run>,
}

#[derive(Serialize, Deserialize)]
struct Run {
    commit: String,
    date: String,
}

#[derive(Serialize, Deserialize)]
struct Point {
    commit: String,
    date: String,
    hosts: BTreeMap<String, Counts>,
}

#[derive(Serialize, Deserialize, Default, Clone, Copy)]
struct Counts {
    critical: usize,
    high: usize,
}

pub struct Diff {
    pub since: String,
    pub since_date: String,
    new: BTreeSet<String>,
    resolved: BTreeSet<String>,
}

impl Diff {
    pub fn summary(&self) -> String {
        format!("+{} new, −{} resolved", self.new.len(), self.resolved.len())
    }
}

pub fn default_path(scope: &str) -> Result<PathBuf> {
    let base = match std::env::var_os("XDG_STATE_HOME").filter(|v| !v.is_empty()) {
        Some(dir) => PathBuf::from(dir),
        None => {
            PathBuf::from(std::env::var_os("HOME").context("HOME is not set")?).join(".local/state")
        }
    };
    Ok(base.join("nix-audit").join(format!("{scope}.json")))
}

impl State {
    pub fn load(path: &Path) -> Result<Self> {
        match std::fs::read(path) {
            Ok(bytes) => serde_json::from_slice(&bytes)
                .with_context(|| format!("parsing {}", path.display())),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(Self::default()),
            Err(error) => Err(error).with_context(|| format!("reading {}", path.display())),
        }
    }

    pub fn save(&self, path: &Path) -> Result<()> {
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)?;
        }
        let tmp = path.with_extension("json.tmp");
        std::fs::write(&tmp, serde_json::to_vec(self)?)?;
        std::fs::rename(&tmp, path).with_context(|| format!("writing {}", path.display()))
    }

    /// The commit of the previous run.
    pub fn since(&self) -> Option<&str> {
        self.last.as_ref().map(|r| r.commit.as_str())
    }

    /// Records this run and returns what changed since the previous run, if there was one.
    /// The trend keeps one point per day, the day's latest run.
    pub fn advance(&mut self, commit: &str, date: &str, findings: &[HostFindings]) -> Option<Diff> {
        let current: BTreeSet<String> = findings
            .iter()
            .flat_map(|f| f.rows.iter().map(|r| key(&f.host, r)))
            .collect();
        let point = Point {
            commit: commit.to_string(),
            date: date.to_string(),
            hosts: findings
                .iter()
                .map(|f| (f.host.clone(), counts(f)))
                .collect(),
        };
        if self.history.last().is_some_and(|p| p.date == date) {
            self.history.pop();
        }
        self.history.push(point);
        if self.history.len() > KEEP {
            self.history.drain(..self.history.len() - KEEP);
        }
        let base = std::mem::replace(&mut self.findings, current);
        let previous = self.last.replace(Run {
            commit: commit.to_string(),
            date: date.to_string(),
        })?;
        Some(Diff {
            since: previous.commit,
            since_date: previous.date,
            new: self.findings.difference(&base).cloned().collect(),
            resolved: base.difference(&self.findings).cloned().collect(),
        })
    }

    /// A line chart of the daily counts for one host, once there are two days to connect.
    pub fn svg(&self, host: &str) -> Option<String> {
        let points: Vec<(&str, Counts)> = self
            .history
            .iter()
            .filter_map(|p| Some((p.date.as_str(), *p.hosts.get(host)?)))
            .collect();
        if points.len() < 2 {
            return None;
        }
        let (width, height) = (640.0, 260.0);
        let (left, right, top, bottom) = (44.0, 136.0, 48.0, 36.0);
        let max = points
            .iter()
            .map(|(_, c)| c.critical + c.high)
            .max()
            .unwrap_or(0)
            .max(1);
        let step = (width - left - right) / (points.len() - 1) as f64;
        let x = |i: usize| left + step * i as f64;
        let y = |v: usize| top + (height - top - bottom) * (1.0 - v as f64 / max as f64);
        let baseline = y(0);

        let mut out = format!(
            r##"<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" font-family="system-ui, sans-serif" font-size="11" fill="#52514e">
<rect width="100%" height="100%" fill="#ffffff"/>
<text x="{left}" y="20" font-size="14" font-weight="600" fill="#1a1a19">{host}: open high and critical findings</text>
<line x1="{left}" y1="{top}" x2="{}" y2="{top}" stroke="#e4e3df"/>
<line x1="{left}" y1="{baseline}" x2="{}" y2="{baseline}" stroke="#a3a29b"/>
<text x="{}" y="{}" text-anchor="end">{max}</text>
<text x="{}" y="{}" text-anchor="end">0</text>
"##,
            width - right,
            width - right,
            left - 6.0,
            top + 4.0,
            left - 6.0,
            baseline + 4.0,
        );
        let every = points.len().div_ceil(8);
        for (i, (date, _)) in points.iter().enumerate() {
            let last = points.len() - 1;
            if i == last || (i % every == 0 && last - i >= every) {
                out.push_str(&format!(
                    "<text x=\"{:.1}\" y=\"{}\" text-anchor=\"middle\">{}</text>\n",
                    x(i),
                    baseline + 18.0,
                    date.get(5..).unwrap_or(date)
                ));
            }
        }
        let series = [
            ("high + critical", "#2a78d6", false),
            ("critical", "#eb6834", true),
        ];
        let value = |c: &Counts, critical_only: bool| {
            if critical_only {
                c.critical
            } else {
                c.critical + c.high
            }
        };
        for (n, (label, color, critical_only)) in series.iter().enumerate() {
            let line: Vec<String> = points
                .iter()
                .enumerate()
                .map(|(i, (_, c))| format!("{:.1},{:.1}", x(i), y(value(c, *critical_only))))
                .collect();
            let last = value(&points[points.len() - 1].1, *critical_only);
            out.push_str(&format!(
                "<polyline fill=\"none\" stroke=\"{color}\" stroke-width=\"2\" stroke-linejoin=\"round\" points=\"{}\"/>\n\
                 <circle cx=\"{:.1}\" cy=\"{:.1}\" r=\"4\" fill=\"{color}\" stroke=\"#ffffff\" stroke-width=\"2\"/>\n\
                 <text x=\"{:.1}\" y=\"{:.1}\" fill=\"#1a1a19\">{last} {label}</text>\n\
                 <rect x=\"{}\" y=\"30\" width=\"10\" height=\"10\" rx=\"2\" fill=\"{color}\"/>\n\
                 <text x=\"{}\" y=\"39\">{label}</text>\n",
                line.join(" "),
                x(points.len() - 1),
                y(last),
                x(points.len() - 1) + 10.0,
                y(last) + 4.0 + 12.0 * n as f64,
                left + 130.0 * n as f64,
                left + 14.0 + 130.0 * n as f64,
            ));
        }
        out.push_str("</svg>\n");
        Some(out)
    }
}

impl Diff {
    pub fn markdown(&self, findings: &[HostFindings]) -> String {
        let diff = self;
        let mut out = String::new();
        let new: Vec<Vec<String>> = findings
            .iter()
            .flat_map(|f| f.rows.iter().map(move |r| (f, r)))
            .filter(|(f, r)| diff.new.contains(&key(&f.host, r)))
            .map(|(f, r)| {
                vec![
                    f.host.clone(),
                    scan::severity_label(r),
                    format!("[{}]({})", field(r, "vuln_id"), field(r, "url")),
                    field(r, "package").to_string(),
                    scan::version(r).to_string(),
                ]
            })
            .collect();
        if !new.is_empty() {
            out.push_str(&table(
                &["Host", "Severity", "New", "Package", "Version"],
                &new,
            ));
            out.push('\n');
        }
        if !diff.resolved.is_empty() {
            let resolved: Vec<String> = diff
                .resolved
                .iter()
                .map(|k| {
                    let mut parts = k.splitn(3, ',');
                    let (host, id, package) = (
                        parts.next().unwrap_or_default(),
                        parts.next().unwrap_or_default(),
                        parts.next().unwrap_or_default(),
                    );
                    format!("~~{id}~~ {package} ({host})")
                })
                .collect();
            out.push_str(&format!("Resolved: {}\n\n", resolved.join(", ")));
        }
        out
    }
}

pub fn short(commit: &str) -> &str {
    &commit[..commit.len().min(7)]
}

// The version stays out of the key, so a bump that keeps the CVE is not a resolve plus a new one.
fn key(host: &str, row: &scan::Row) -> String {
    format!("{host},{},{}", field(row, "vuln_id"), field(row, "package"))
}

fn counts(host: &HostFindings) -> Counts {
    let mut counts = Counts::default();
    for row in &host.rows {
        if scan::rank(field(row, "severity")) >= scan::rank("critical") {
            counts.critical += 1;
        } else {
            counts.high += 1;
        }
    }
    counts
}

#[cfg(test)]
mod tests {
    use super::*;

    fn host(name: &str, vulns: &[(&str, &str, &str)]) -> HostFindings {
        HostFindings {
            host: name.to_string(),
            rows: vulns
                .iter()
                .map(|(id, package, severity)| {
                    [
                        ("vuln_id", *id),
                        ("package", *package),
                        ("severity", *severity),
                        ("url", "https://example.org"),
                    ]
                    .into_iter()
                    .map(|(k, v)| (k.to_string(), v.to_string()))
                    .collect()
                })
                .collect(),
            below: Vec::new(),
            suppressed: Vec::new(),
            toplevel: None,
            link: None,
        }
    }

    #[test]
    fn first_run_has_no_diff() {
        let mut state = State::default();
        assert!(
            state
                .advance("a", "2026-01-01", &[host("h", &[("CVE-1", "p", "9.8")])])
                .is_none()
        );
        assert!(state.svg("h").is_none());
    }

    #[test]
    fn diffs_against_the_previous_day() {
        let mut state = State::default();
        state.advance(
            "a",
            "2026-01-01",
            &[host("h", &[("CVE-1", "p", "9.8"), ("CVE-2", "q", "7.5")])],
        );
        let findings = [host("h", &[("CVE-2", "q", "7.5"), ("CVE-3", "r", "8.0")])];
        let diff = state.advance("b", "2026-01-02", &findings).unwrap();
        assert_eq!(diff.since, "a");
        assert_eq!(diff.since_date, "2026-01-01");
        assert_eq!(diff.new, BTreeSet::from(["h,CVE-3,r".to_string()]));
        assert_eq!(diff.resolved, BTreeSet::from(["h,CVE-1,p".to_string()]));

        assert_eq!(diff.summary(), "+1 new, −1 resolved");
        assert!(diff.markdown(&findings).contains("~~CVE-1~~ p (h)"));
        assert!(diff.markdown(&findings).contains("[CVE-3]"));

        let svg = state.svg("h").unwrap();
        assert!(svg.contains(">01-02<"));
        assert!(svg.contains(">2 high + critical<"));
        assert!(svg.contains(">0 critical<"));
    }

    #[test]
    fn same_commit_on_a_new_day_still_diffs() {
        let mut state = State::default();
        state.advance("a", "2026-01-01", &[host("h", &[])]);
        let diff = state
            .advance("a", "2026-01-02", &[host("h", &[("CVE-1", "p", "9.8")])])
            .unwrap();
        assert_eq!(diff.new.len(), 1);
        assert_eq!(state.history.len(), 2);
    }

    #[test]
    fn second_run_on_a_day_diffs_against_the_first_and_replaces_its_point() {
        let mut state = State::default();
        state.advance("a", "2026-01-01", &[host("h", &[("CVE-1", "p", "9.8")])]);
        state.advance("b", "2026-01-02", &[host("h", &[])]);
        assert_eq!(state.since(), Some("b"));
        let diff = state
            .advance("c", "2026-01-02", &[host("h", &[("CVE-2", "q", "7.5")])])
            .unwrap();
        assert_eq!(state.history.len(), 2);
        assert_eq!(state.history[1].commit, "c");
        assert_eq!(diff.since, "b");
        assert_eq!(diff.new.len(), 1);
        assert!(diff.resolved.is_empty());
    }

    #[test]
    fn keeps_a_bounded_history() {
        let mut state = State::default();
        for i in 0..KEEP + 5 {
            state.advance(&i.to_string(), &i.to_string(), &[host("h", &[])]);
        }
        assert_eq!(state.history.len(), KEEP);
        assert_eq!(state.history[0].commit, "5");
    }

    #[test]
    fn round_trips_through_the_state_file() {
        let dir = std::env::temp_dir().join(format!("nix-audit-test-{}", std::process::id()));
        let path = dir.join("scope.json");
        assert!(State::load(&path).unwrap().history.is_empty());

        let mut state = State::default();
        state.advance("a", "2026-01-01", &[host("h", &[("CVE-1", "p", "9.8")])]);
        state.save(&path).unwrap();
        let loaded = State::load(&path).unwrap();
        assert_eq!(loaded.history.len(), 1);
        assert_eq!(loaded.findings, state.findings);
        std::fs::remove_dir_all(dir).unwrap();
    }
}
