use crate::scan::{HostFindings, Row, SEVERITIES, field, rank, version};
use anyhow::{Context, Result};
use base64::Engine;
use serde_json::{Map, Value, json};
use std::collections::{BTreeMap, HashMap, HashSet, VecDeque};
use std::io::{Write, stderr};
use std::os::fd::AsFd;
use std::path::Path;
use std::process::{Command, Stdio};

const SUNSHINE: &str = "https://cyclonedx.github.io/Sunshine/";
const MAX_LINK: usize = 1 << 20;

pub fn write(dir: Option<&Path>, findings: &mut [HostFindings]) {
    let scratch = std::env::temp_dir().join(format!("nix-audit-cdx-{}", std::process::id()));
    for host in findings.iter_mut() {
        let out = dir.unwrap_or(&scratch);
        match build(out, host) {
            Ok(link) => host.link = link,
            Err(error) => eprintln!("warning: no CycloneDX report for {}: {error:#}", host.host),
        }
    }
}

fn build(dir: &Path, host: &HostFindings) -> Result<Option<String>> {
    let toplevel = host
        .toplevel
        .as_deref()
        .context("the scanned store path is unknown")?;
    std::fs::create_dir_all(dir)?;
    let path = dir.join(format!("{}.cdx.json", host.host));
    let mut bom = sbom(toplevel, &path)?;
    annotate(&mut bom, host);
    std::fs::write(&path, serde_json::to_string_pretty(&bom)?)?;

    let full = stable(&bom);
    let mut link = permalink(&full)?;
    if link.len() > MAX_LINK {
        eprintln!(
            "warning: full Sunshine link for {} is {} bytes, linking only the affected paths",
            host.host,
            link.len()
        );
        link = permalink(&paths_only(&full))?;
    }
    if link.len() > MAX_LINK {
        eprintln!(
            "warning: Sunshine link for {} is still too long, leaving it out",
            host.host
        );
        return Ok(None);
    }
    Ok(Some(link))
}

fn sbom(toplevel: &str, path: &Path) -> Result<Value> {
    // A bare store path may have no nixpkgs to read metadata from; licenses are nice to have.
    if !sbomnix(toplevel, path, false)? && !sbomnix(toplevel, path, true)? {
        anyhow::bail!("sbomnix failed");
    }
    Ok(serde_json::from_slice(&std::fs::read(path)?)?)
}

fn sbomnix(toplevel: &str, path: &Path, exclude_meta: bool) -> Result<bool> {
    // sbomnix also drops sbom.csv and sbom.spdx.json into its working directory.
    let scratch = std::env::temp_dir().join(format!("nix-audit-sbomnix-{}", std::process::id()));
    std::fs::create_dir_all(&scratch)?;
    let mut cmd = Command::new("sbomnix");
    cmd.current_dir(&scratch)
        .arg("--cdx")
        .arg(std::path::absolute(path)?);
    if exclude_meta {
        cmd.arg("--exclude-meta");
    }
    cmd.arg(toplevel);
    cmd.stdout(Stdio::from(stderr().as_fd().try_clone_to_owned()?));
    Ok(cmd.status().context("running sbomnix")?.success())
}

fn annotate(bom: &mut Value, host: &HostFindings) {
    let mut refs: HashMap<(String, String), Vec<String>> = HashMap::new();
    for c in bom["components"].as_array().into_iter().flatten() {
        if let Some(r) = c["bom-ref"].as_str() {
            refs.entry((str_of(c, "name"), str_of(c, "version")))
                .or_default()
                .push(r.to_string());
        }
    }

    let mut stubs = Vec::new();
    let mut seen = HashSet::new();
    let mut vulns = Vec::new();
    let whitelisted = host.suppressed.iter().map(|r| (r, true));
    let open = host.rows.iter().chain(&host.below).map(|r| (r, false));
    for (row, suppressed) in open.chain(whitelisted) {
        let key = (field(row, "package").to_string(), version(row).to_string());
        let id = format!("{}@{}-{}", field(row, "vuln_id"), key.0, key.1);
        if !seen.insert(id.clone()) {
            continue;
        }
        let affected = refs.entry(key.clone()).or_insert_with(|| {
            let purl = format!("pkg:nix/{}@{}", key.0, key.1);
            stubs.push(json!({
                "type": "library",
                "bom-ref": purl,
                "name": key.0,
                "version": key.1,
                "purl": purl,
            }));
            vec![purl]
        });
        vulns.push(vulnerability(row, id, affected, suppressed));
    }

    if let Some(components) = bom["components"].as_array_mut() {
        components.extend(stubs);
    }
    bom["vulnerabilities"] = Value::Array(vulns);
    if let Some(tools) = bom["metadata"]["tools"].as_array_mut() {
        tools.push(json!({ "name": "nix-audit", "version": env!("CARGO_PKG_VERSION") }));
    }
}

fn vulnerability(row: &Row, id: String, affected: &[String], suppressed: bool) -> Value {
    let raw = field(row, "severity");
    let mut rating = Map::new();
    if let Ok(score) = raw.trim().parse::<f64>() {
        rating.insert("score".into(), json!(score));
        rating.insert("method".into(), json!("CVSSv3"));
    }
    rating.insert("severity".into(), json!(severity(raw)));

    let analysis = if suppressed {
        json!({ "state": "not_affected", "detail": field(row, "whitelist_comment") })
    } else {
        json!({ "state": "in_triage" })
    };
    let properties: Vec<Value> = [("via", "via"), ("triage", "classify"), ("scanners", "sum")]
        .into_iter()
        .filter(|(_, column)| !field(row, column).is_empty())
        .map(|(name, column)| json!({ "name": format!("nix-audit:{name}"), "value": field(row, column) }))
        .collect();

    let mut vuln = json!({
        "bom-ref": id,
        "id": field(row, "vuln_id"),
        "ratings": [rating],
        "affects": affected.iter().map(|r| json!({ "ref": r })).collect::<Vec<_>>(),
        "analysis": analysis,
    });
    if !field(row, "url").is_empty() {
        vuln["source"] = json!({ "url": field(row, "url") });
    }
    if !properties.is_empty() {
        vuln["properties"] = Value::Array(properties);
    }
    vuln
}

fn severity(raw: &str) -> &'static str {
    match rank(raw) {
        0 => "unknown",
        1 => "info",
        r => SEVERITIES[r - 1],
    }
}

// The link sits in the issue body, which must stay unchanged while the findings do.
// Sunshine ignores VEX analysis, so whitelisted findings stay in the file but not the link.
fn stable(bom: &Value) -> Value {
    let mut out = bom.clone();
    if let Some(top) = out.as_object_mut() {
        top.remove("serialNumber");
    }
    if let Some(vulns) = out["vulnerabilities"].as_array_mut() {
        vulns.retain(|v| v["analysis"]["state"] != "not_affected");
    }
    if let Some(metadata) = out["metadata"].as_object_mut() {
        metadata.remove("timestamp");
    }
    out
}

/// Keeps every vulnerability but only the components on the shortest path to each one,
/// for closures too large to fit in a URL whole.
fn paths_only(bom: &Value) -> Value {
    let mut children: HashMap<&str, Vec<&str>> = HashMap::new();
    for d in bom["dependencies"].as_array().into_iter().flatten() {
        if let Some(r) = d["ref"].as_str() {
            let deps = d["dependsOn"].as_array().into_iter().flatten();
            children.insert(r, deps.filter_map(Value::as_str).collect());
        }
    }

    let root = bom["metadata"]["component"]["bom-ref"]
        .as_str()
        .unwrap_or_default();
    let mut parents: HashMap<&str, &str> = HashMap::new();
    let mut queue = VecDeque::from([root]);
    while let Some(node) = queue.pop_front() {
        for child in children.get(node).into_iter().flatten() {
            if *child != root && !parents.contains_key(child) {
                parents.insert(child, node);
                queue.push_back(child);
            }
        }
    }

    let mut keep: HashSet<&str> = HashSet::new();
    let mut edges: BTreeMap<&str, Vec<&str>> = BTreeMap::new();
    let affected = bom["vulnerabilities"].as_array().into_iter().flatten();
    for r in affected.flat_map(|v| v["affects"].as_array().into_iter().flatten()) {
        let mut node = r["ref"].as_str().unwrap_or_default();
        while keep.insert(node) {
            let Some(parent) = parents.get(node) else {
                break;
            };
            edges.entry(parent).or_default().push(node);
            node = parent;
        }
    }

    let mut out = bom.clone();
    let components = bom["components"].as_array().into_iter().flatten();
    out["components"] = components
        .filter(|c| keep.contains(c["bom-ref"].as_str().unwrap_or_default()))
        .cloned()
        .collect();
    out["dependencies"] = edges
        .into_iter()
        .map(|(r, mut deps)| {
            deps.sort_unstable();
            json!({ "ref": r, "dependsOn": deps })
        })
        .collect();
    out
}

/// Sunshine reads its permalinks as base64 of an LZMA-alone stream in the URL fragment,
/// which never leaves the browser.
fn permalink(bom: &Value) -> Result<String> {
    let options = xz2::stream::LzmaOptions::new_preset(6)?;
    let stream = xz2::stream::Stream::new_lzma_encoder(&options)?;
    let mut encoder = xz2::write::XzEncoder::new_stream(Vec::new(), stream);
    encoder.write_all(&serde_json::to_vec(bom)?)?;
    let compressed = encoder.finish()?;
    let encoded = base64::engine::general_purpose::STANDARD.encode(compressed);
    Ok(format!("{SUNSHINE}#{encoded}"))
}

fn str_of(value: &Value, key: &str) -> String {
    value[key].as_str().unwrap_or_default().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    fn row(id: &str, package: &str, version: &str, severity: &str) -> Row {
        [
            ("vuln_id", id),
            ("package", package),
            ("version_local", version),
            ("severity", severity),
            ("url", "https://example.org"),
            ("whitelist_comment", "not us"),
        ]
        .into_iter()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect()
    }

    fn fixture() -> (Value, HostFindings) {
        let bom = json!({
            "bomFormat": "CycloneDX",
            "specVersion": "1.4",
            "metadata": { "tools": [], "component": { "bom-ref": "/top" } },
            "components": [
                { "bom-ref": "/path", "name": "system-path", "version": "" },
                { "bom-ref": "/curl", "name": "curl", "version": "8.0" },
                { "bom-ref": "/bash", "name": "bash", "version": "5.2" },
                { "bom-ref": "/idle", "name": "idle", "version": "1" },
            ],
            "dependencies": [
                { "ref": "/top", "dependsOn": ["/path", "/idle"] },
                { "ref": "/path", "dependsOn": ["/curl", "/bash"] },
            ],
        });
        let host = HostFindings {
            host: String::from("test"),
            rows: vec![row("CVE-1", "curl", "8.0", "9.8")],
            below: vec![row("CVE-2", "gone", "1.0", "5.0")],
            suppressed: vec![row("CVE-3", "bash", "5.2", "7.5")],
            toplevel: None,
            link: None,
            incomplete: false,
        };
        (bom, host)
    }

    #[test]
    fn annotates_every_finding() {
        let (mut bom, host) = fixture();
        annotate(&mut bom, &host);
        let vulns = bom["vulnerabilities"].as_array().unwrap();
        assert_eq!(vulns.len(), 3);
        assert_eq!(vulns[0]["affects"][0]["ref"], "/curl");
        assert_eq!(vulns[0]["ratings"][0]["severity"], "critical");
        assert_eq!(vulns[0]["analysis"]["state"], "in_triage");
        assert_eq!(vulns[1]["affects"][0]["ref"], "pkg:nix/gone@1.0");
        assert_eq!(vulns[2]["analysis"]["state"], "not_affected");
        assert_eq!(vulns[2]["analysis"]["detail"], "not us");
        assert_eq!(bom["components"].as_array().unwrap().len(), 5);
    }

    #[test]
    fn link_keeps_open_findings_and_their_paths_only() {
        let (mut bom, host) = fixture();
        annotate(&mut bom, &host);
        let small = paths_only(&stable(&bom));
        assert_eq!(small["vulnerabilities"].as_array().unwrap().len(), 2);
        let mut kept: Vec<&str> = small["components"]
            .as_array()
            .unwrap()
            .iter()
            .map(|c| c["bom-ref"].as_str().unwrap())
            .collect();
        kept.sort();
        assert_eq!(kept, ["/curl", "/path", "pkg:nix/gone@1.0"]);
    }

    #[test]
    fn permalink_is_an_lzma_alone_stream() {
        let bom = json!({ "bomFormat": "CycloneDX" });
        let link = permalink(&bom).unwrap();
        let fragment = link.strip_prefix(&format!("{SUNSHINE}#")).unwrap();
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(fragment)
            .unwrap();
        assert_eq!(bytes[0], 0x5d);
        let stream = xz2::stream::Stream::new_lzma_decoder(u64::MAX).unwrap();
        let mut json = String::new();
        xz2::read::XzDecoder::new_stream(&bytes[..], stream)
            .read_to_string(&mut json)
            .unwrap();
        assert_eq!(serde_json::from_str::<Value>(&json).unwrap(), bom);
    }
}
