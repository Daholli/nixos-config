use crate::{BumpsArgs, git, table};
use anyhow::{Context, Result, bail};
use serde::Deserialize;
use std::collections::BTreeMap;
use std::path::Path;
use std::process::Command;

const WATCHLIST: &[&str] = &[
    "adguardhome",
    "attic-server",
    "element-call",
    "element-web",
    "factorio-headless",
    "fail2ban",
    "forgejo",
    "forgejo-lts",
    "forgejo-runner",
    "home-assistant",
    "hydra",
    "immich",
    "livekit",
    "lix",
    "lk-jwt-service",
    "matrix-authentication-service",
    "matrix-synapse",
    "mautrix-discord",
    "mautrix-signal",
    "minecraft-server",
    "nginx",
    "nix-serve",
    "postgresql",
    "postgresql_16",
    "samba",
    "tailscale",
];

const APPLY: &str = r#"p: builtins.listToAttrs (map (n:
  let
    v = if p ? ${n} then {
      version = p.${n}.version or null;
      changelog = p.${n}.meta.changelog or null;
      homepage = p.${n}.meta.homepage or null;
    } else null;
    r = builtins.tryEval (builtins.deepSeq v v);
  in { name = n; value = if r.success then r.value else null; }) @NAMES@)"#;

#[derive(Deserialize, Clone)]
pub struct Pkg {
    pub version: Option<String>,
    pub changelog: Option<String>,
    pub homepage: Option<String>,
}

pub struct Change {
    pub name: String,
    pub from: String,
    pub to: String,
    pub major: bool,
    pub link: Option<String>,
}

pub struct Bumps {
    pub from: String,
    pub to: String,
    pub changes: Vec<Change>,
    pub missing: Vec<String>,
    pub nvd: Option<String>,
}

pub fn run(root: &Path, args: &BumpsArgs) -> Result<Bumps> {
    let from_ref = flake_ref(root, &args.from)?;
    let (to_label, to_ref) = match &args.to {
        Some(rev) => (rev.clone(), flake_ref(root, rev)?),
        None => (String::from("working tree"), String::from(".")),
    };

    let old = eval(root, &from_ref, &args.host)?;
    let new = eval(root, &to_ref, &args.host)?;

    let mut changes = Vec::new();
    let mut missing = Vec::new();
    for name in WATCHLIST {
        let (before, after) = (
            old.get(*name).and_then(Clone::clone),
            new.get(*name).and_then(Clone::clone),
        );
        match (before, after) {
            (Some(before), Some(after)) => {
                let (from, to) = (
                    before.version.unwrap_or_default(),
                    after.version.unwrap_or_default(),
                );
                if from != to {
                    changes.push(Change {
                        name: name.to_string(),
                        major: is_major(&from, &to),
                        from,
                        to,
                        link: after.changelog.or(after.homepage),
                    });
                }
            }
            _ => missing.push(name.to_string()),
        }
    }

    let nvd = if args.all {
        Some(nvd_diff(root, &from_ref, &to_ref, &args.host)?)
    } else {
        None
    };

    Ok(Bumps {
        from: args.from.clone(),
        to: to_label,
        changes,
        missing,
        nvd,
    })
}

pub fn markdown(bumps: &Bumps) -> String {
    let mut out = format!("## Watchlist bumps — {} → {}\n\n", bumps.from, bumps.to);
    if bumps.changes.is_empty() {
        out.push_str("No watchlist package changed version.\n\n");
    } else {
        let rows: Vec<Vec<String>> = bumps
            .changes
            .iter()
            .map(|c| {
                vec![
                    c.name.clone(),
                    c.from.clone(),
                    c.to.clone(),
                    if c.major {
                        String::from("**yes**")
                    } else {
                        String::new()
                    },
                    c.link
                        .clone()
                        .map_or(String::new(), |l| format!("[notes]({l})")),
                ]
            })
            .collect();
        out.push_str(&table(
            &["Package", "From", "To", "Major", "Changelog"],
            &rows,
        ));
        out.push('\n');
    }
    if !bumps.missing.is_empty() {
        out.push_str(&format!(
            "_Not evaluable in both revisions, check for a rename: {}._\n\n",
            bumps.missing.join(", ")
        ));
    }
    if let Some(diff) = &bumps.nvd {
        out.push_str(&format!(
            "<details><summary>Full closure diff</summary>\n\n```\n{diff}\n```\n\n</details>\n\n"
        ));
    }
    out
}

fn eval(root: &Path, flake_ref: &str, host: &str) -> Result<BTreeMap<String, Option<Pkg>>> {
    let names: Vec<String> = WATCHLIST.iter().map(|n| format!("\"{n}\"")).collect();
    let apply = APPLY.replace("@NAMES@", &format!("[ {} ]", names.join(" ")));
    let out = Command::new("nix")
        .current_dir(root)
        .args([
            "eval",
            "--json",
            &format!("{flake_ref}#nixosConfigurations.{host}.pkgs"),
            "--apply",
            &apply,
        ])
        .output()
        .context("running nix eval")?;
    if !out.status.success() {
        bail!(
            "nix eval failed for {flake_ref}: {}",
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(serde_json::from_slice(&out.stdout)?)
}

fn nvd_diff(root: &Path, from_ref: &str, to_ref: &str, host: &str) -> Result<String> {
    let old = toplevel(root, from_ref, host)?;
    let new = toplevel(root, to_ref, host)?;
    let out = Command::new("nvd")
        .args(["diff", &old, &new])
        .output()
        .context("running nvd")?;
    if !out.status.success() {
        bail!(
            "nvd diff failed: {}",
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(String::from_utf8(out.stdout)?.trim().to_string())
}

fn toplevel(root: &Path, flake_ref: &str, host: &str) -> Result<String> {
    let out = Command::new("nix")
        .current_dir(root)
        .args([
            "build",
            "--no-link",
            "--print-out-paths",
            &format!("{flake_ref}#nixosConfigurations.{host}.config.system.build.toplevel"),
        ])
        .output()
        .context("running nix build")?;
    if !out.status.success() {
        bail!(
            "building the toplevel for {flake_ref} failed: {}",
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(String::from_utf8(out.stdout)?.trim().to_string())
}

fn flake_ref(root: &Path, rev: &str) -> Result<String> {
    let resolved = git(root, &["rev-parse", rev])?;
    // CI checks out shallow, and nix refuses to fetch from a shallow repository unless asked.
    Ok(format!(
        "git+file://{}?rev={}&shallow=1",
        root.display(),
        resolved
    ))
}

fn is_major(from: &str, to: &str) -> bool {
    match (major(from), major(to)) {
        (Some(a), Some(b)) => a != b,
        _ => false,
    }
}

// `0-unstable-<date>` versions carry no semver, so a changed date is not a major bump.
fn major(version: &str) -> Option<u64> {
    if version.contains("unstable") {
        return None;
    }
    version
        .chars()
        .take_while(char::is_ascii_digit)
        .collect::<String>()
        .parse()
        .ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn major_bumps() {
        assert!(is_major("17.0.1", "18.6"));
        assert!(!is_major("1.161.0", "1.162.0"));
        assert!(!is_major("0-unstable-2026-03-16", "0-unstable-2026-09-01"));
        assert!(!is_major("", "1.0"));
    }
}
