use crate::scan::{self, HostFindings, field};
use crate::table;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

const MARKER: &str = "<!-- nix-audit-state:";
const KEEP: usize = 20;

/// Carried between runs in a hidden marker of the tracking issue body.
#[derive(Default, Serialize, Deserialize)]
pub struct State {
    history: Vec<Point>,
    findings: BTreeSet<String>,
    // The finding set of the run before the latest commit, so a rerun of the same commit
    // still diffs against the change before it.
    base: BTreeSet<String>,
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
    new: BTreeSet<String>,
    resolved: BTreeSet<String>,
}

impl Diff {
    pub fn summary(&self) -> String {
        format!("+{} new, −{} resolved", self.new.len(), self.resolved.len())
    }
}

impl State {
    pub fn from_body(body: &str) -> Self {
        crate::forgejo::marker(body, MARKER)
            .and_then(|json| serde_json::from_str(&json).ok())
            .unwrap_or_default()
    }

    pub fn marker(&self) -> String {
        format!(
            "{MARKER} {} -->\n",
            serde_json::to_string(self).unwrap_or_default()
        )
    }

    /// Records this run and returns what changed since the previous commit, if there was one.
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
        if self.history.last().is_some_and(|p| p.commit == commit) {
            self.history.pop();
        } else {
            self.base = std::mem::take(&mut self.findings);
        }
        self.history.push(point);
        if self.history.len() > KEEP {
            self.history.drain(..self.history.len() - KEEP);
        }
        self.findings = current;

        let previous = self.history.iter().rev().nth(1)?;
        Some(Diff {
            since: previous.commit.clone(),
            new: self.findings.difference(&self.base).cloned().collect(),
            resolved: self.base.difference(&self.findings).cloned().collect(),
        })
    }

    pub fn markdown(&self, findings: &[HostFindings]) -> String {
        if self.history.len() < 2 {
            return String::new();
        }
        let mut out = String::from("## Trend\n\n");
        for host in findings {
            let points: Vec<(&str, Counts)> = self
                .history
                .iter()
                .filter_map(|p| Some((p.commit.as_str(), *p.hosts.get(&host.host)?)))
                .collect();
            if points.len() < 2 {
                continue;
            }
            let labels: Vec<String> = points
                .iter()
                .map(|(c, _)| format!("\"{}\"", short(c)))
                .collect();
            let total: Vec<usize> = points.iter().map(|(_, c)| c.critical + c.high).collect();
            let critical: Vec<usize> = points.iter().map(|(_, c)| c.critical).collect();
            let max = total.iter().copied().max().unwrap_or(0).max(1);
            out.push_str(&format!(
                "```mermaid\nxychart-beta\n  title \"{}\"\n  x-axis [{}]\n  y-axis \"findings\" 0 --> {max}\n  line {:?}\n  line {:?}\n```\n\n",
                host.host,
                labels.join(", "),
                total,
                critical
            ));
        }
        out.push_str("_Upper line: high and critical, lower line: critical only._\n\n");
        out
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
                .advance("a", "d", &[host("h", &[("CVE-1", "p", "9.8")])])
                .is_none()
        );
        assert!(state.markdown(&[]).is_empty());
    }

    #[test]
    fn diffs_against_the_previous_commit() {
        let mut state = State::default();
        state.advance(
            "a",
            "d",
            &[host("h", &[("CVE-1", "p", "9.8"), ("CVE-2", "q", "7.5")])],
        );
        let findings = [host("h", &[("CVE-2", "q", "7.5"), ("CVE-3", "r", "8.0")])];
        let diff = state.advance("b", "d", &findings).unwrap();
        assert_eq!(diff.since, "a");
        assert_eq!(diff.new, BTreeSet::from(["h,CVE-3,r".to_string()]));
        assert_eq!(diff.resolved, BTreeSet::from(["h,CVE-1,p".to_string()]));

        assert_eq!(diff.summary(), "+1 new, −1 resolved");
        assert!(diff.markdown(&findings).contains("~~CVE-1~~ p (h)"));
        assert!(diff.markdown(&findings).contains("[CVE-3]"));
        assert!(
            state
                .markdown(&findings)
                .contains("line [2, 2]\n  line [1, 0]")
        );
    }

    #[test]
    fn rerun_of_a_commit_replaces_its_point_and_keeps_the_base() {
        let mut state = State::default();
        state.advance("a", "d", &[host("h", &[("CVE-1", "p", "9.8")])]);
        state.advance("b", "d", &[host("h", &[])]);
        let diff = state.advance("b", "d", &[host("h", &[])]).unwrap();
        assert_eq!(state.history.len(), 2);
        assert_eq!(diff.since, "a");
        assert_eq!(diff.resolved.len(), 1);
    }

    #[test]
    fn keeps_a_bounded_history() {
        let mut state = State::default();
        for i in 0..KEEP + 5 {
            state.advance(&i.to_string(), "d", &[host("h", &[])]);
        }
        assert_eq!(state.history.len(), KEEP);
        assert_eq!(state.history[0].commit, "5");
    }

    #[test]
    fn round_trips_through_the_issue_body() {
        let mut state = State::default();
        state.advance("a", "d", &[host("h", &[("CVE-1", "p", "9.8")])]);
        let body = format!("# report\n{}", state.marker());
        let parsed = State::from_body(&body);
        assert_eq!(parsed.history.len(), 1);
        assert_eq!(parsed.findings, state.findings);
        assert!(
            State::from_body("<!-- nix-audit-state: garbage -->")
                .history
                .is_empty()
        );
    }
}
