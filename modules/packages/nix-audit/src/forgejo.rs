use anyhow::{Context, Result};
use serde_json::{Value, json};
use std::fmt;

const MARKER: &str = "<!-- fingerprint:";

pub struct Config {
    pub url: String,
    pub repo: String,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            url: std::env::var("FORGEJO_URL")
                .unwrap_or_else(|_| String::from("https://git.christophhollizeck.dev")),
            repo: std::env::var("FORGEJO_REPO")
                .unwrap_or_else(|_| String::from("Daholli/nixos-config")),
        }
    }
}

pub enum Action {
    Created(u64),
    Updated(u64),
    Refreshed(u64),
    Unchanged(u64),
}

impl fmt::Display for Action {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Action::Created(n) => write!(f, "created issue #{n}"),
            Action::Updated(n) => write!(f, "updated issue #{n} and commented"),
            Action::Refreshed(n) => write!(f, "refreshed issue #{n} without commenting"),
            Action::Unchanged(n) => write!(f, "issue #{n} unchanged"),
        }
    }
}

pub fn upsert(
    config: &Config,
    token: &str,
    title: &str,
    body: &str,
    fingerprint: &str,
    comment: &str,
    notify: bool,
) -> Result<Action> {
    let auth = format!("token {token}");
    let base = format!(
        "{}/api/v1/repos/{}",
        config.url.trim_end_matches('/'),
        config.repo
    );

    let open: Vec<Value> = ureq::get(&format!("{base}/issues?state=open&type=issues&limit=50"))
        .set("Authorization", &auth)
        .call()
        .context("listing issues")?
        .into_json()?;
    let existing = open
        .into_iter()
        .find(|issue| issue["title"].as_str() == Some(title));

    let Some(issue) = existing else {
        let created: Value = ureq::post(&format!("{base}/issues"))
            .set("Authorization", &auth)
            .send_json(json!({ "title": title, "body": body }))
            .context("creating the issue")?
            .into_json()?;
        return Ok(Action::Created(number(&created)?));
    };

    let number = number(&issue)?;
    let current = issue["body"].as_str().unwrap_or_default();
    // A body edit notifies nobody, so the issue can always carry the latest report; only a
    // changed finding set or a watchlist bump is worth a comment.
    let notify = notify || fingerprint_of(current).as_deref() != Some(fingerprint);
    let stale = normalized(current) != normalized(body);

    if !stale && !notify {
        return Ok(Action::Unchanged(number));
    }
    if stale {
        ureq::request("PATCH", &format!("{base}/issues/{number}"))
            .set("Authorization", &auth)
            .send_json(json!({ "body": body }))
            .context("updating the issue body")?;
    }
    if !notify {
        return Ok(Action::Refreshed(number));
    }
    ureq::post(&format!("{base}/issues/{number}/comments"))
        .set("Authorization", &auth)
        .send_json(json!({ "body": comment }))
        .context("commenting on the issue")?;
    Ok(Action::Updated(number))
}

// Forgejo hands bodies back with CRLF line endings.
fn normalized(body: &str) -> String {
    body.replace("\r\n", "\n").trim_end().to_string()
}

fn number(issue: &Value) -> Result<u64> {
    issue["number"]
        .as_u64()
        .context("issue response without a number")
}

fn fingerprint_of(body: &str) -> Option<String> {
    body.lines().find_map(|line| {
        let rest = line.trim().strip_prefix(MARKER)?.strip_suffix("-->")?;
        Some(rest.trim().to_string())
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_fingerprint_marker() {
        let body = "# report\n\nstuff\n<!-- fingerprint: abc123 -->\n";
        assert_eq!(fingerprint_of(body).as_deref(), Some("abc123"));
        assert_eq!(fingerprint_of("no marker here"), None);
    }

    #[test]
    fn normalizes_line_endings_and_trailing_space() {
        assert_eq!(normalized("a\r\nb\n\n"), normalized("a\nb"));
    }
}
