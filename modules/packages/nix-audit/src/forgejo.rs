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
    Unchanged(u64),
}

impl fmt::Display for Action {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Action::Created(n) => write!(f, "created issue #{n}"),
            Action::Updated(n) => write!(f, "updated issue #{n}"),
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
    if fingerprint_of(issue["body"].as_str().unwrap_or_default()).as_deref() == Some(fingerprint) {
        return Ok(Action::Unchanged(number));
    }
    ureq::request("PATCH", &format!("{base}/issues/{number}"))
        .set("Authorization", &auth)
        .send_json(json!({ "body": body }))
        .context("updating the issue body")?;
    ureq::post(&format!("{base}/issues/{number}/comments"))
        .set("Authorization", &auth)
        .send_json(json!({ "body": comment }))
        .context("commenting on the issue")?;
    Ok(Action::Updated(number))
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
}
