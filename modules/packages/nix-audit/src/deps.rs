use anyhow::{Context, Result};
use std::collections::{HashMap, VecDeque};
use std::process::Command;

// Nodes of the toplevel closure that say nothing about *why* a package is installed.
const STRUCTURAL: [&str; 6] = [
    "system-path",
    "etc",
    "sw",
    "system-units",
    "user-units",
    "local-cmds",
];

pub struct Graph {
    root: String,
    parents: HashMap<String, String>,
}

impl Graph {
    pub fn load(toplevel: &str) -> Result<Self> {
        // /run/current-system and ./result are symlinks; the graph is keyed by the store
        // path they resolve to.
        let resolved = std::fs::canonicalize(toplevel)
            .map_or_else(|_| toplevel.to_string(), |p| p.display().to_string());
        let out = Command::new("nix-store")
            .args(["--query", "--graph", &resolved])
            .output()
            .context("running nix-store --query --graph")?;
        Self::from_dot(&String::from_utf8_lossy(&out.stdout), node_of(&resolved))
    }

    fn from_dot(dot: &str, root: &str) -> Result<Self> {
        // nix-store draws "dependency" -> "dependent", so reverse it to walk outwards
        // from the toplevel.
        let mut children: HashMap<&str, Vec<&str>> = HashMap::new();
        for line in dot.lines() {
            let Some((left, rest)) = line.split_once("\" -> \"") else {
                continue;
            };
            let Some(dependency) = left.strip_prefix('"') else {
                continue;
            };
            let Some((dependent, _)) = rest.split_once('"') else {
                continue;
            };
            children.entry(dependent).or_default().push(dependency);
        }

        let root = root.to_string();
        let mut parents: HashMap<String, String> = HashMap::new();
        let mut queue = VecDeque::from([root.clone()]);
        while let Some(node) = queue.pop_front() {
            for child in children.get(node.as_str()).into_iter().flatten() {
                if *child != root && !parents.contains_key(*child) {
                    parents.insert((*child).to_string(), node.clone());
                    queue.push_back((*child).to_string());
                }
            }
        }
        Ok(Self { root, parents })
    }

    /// The top-level thing that drags `package-version` into the closure.
    pub fn introducer(&self, key: &str) -> Option<String> {
        let node = self
            .parents
            .keys()
            .filter(|n| matches(name_of(n), key))
            .min_by_key(|n| self.depth(n))?;

        let mut chain = vec![node.clone()];
        let mut cursor = node.clone();
        while let Some(parent) = self.parents.get(&cursor) {
            chain.push(parent.clone());
            cursor = parent.clone();
        }
        chain.reverse();

        chain
            .iter()
            .skip(1)
            .map(|n| name_of(n))
            .find(|n| !STRUCTURAL.contains(n))
            .map(str::to_string)
    }

    fn depth(&self, node: &str) -> usize {
        let mut depth = 0;
        let mut cursor = node;
        while let Some(parent) = self.parents.get(cursor) {
            if parent == &self.root {
                break;
            }
            cursor = parent;
            depth += 1;
        }
        depth
    }
}

fn matches(name: &str, key: &str) -> bool {
    name == key
        || name
            .strip_prefix(key)
            .is_some_and(|rest| rest.starts_with('-'))
}

fn node_of(path: &str) -> &str {
    path.rsplit('/').next().unwrap_or(path)
}

fn name_of(node: &str) -> &str {
    node.split_once('-').map_or(node, |(_, name)| name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_hashes_and_matches_outputs() {
        assert_eq!(
            name_of("0ccz6g5fijp8kj4n1rgm1rv29qxdpy7v-libpng-1.2.59"),
            "libpng-1.2.59"
        );
        assert!(matches("libpng-1.2.59", "libpng-1.2.59"));
        assert!(matches("glibc-2.42-84-bin", "glibc-2.42-84"));
        assert!(!matches("libpng-1.6.50", "libpng-1.2.59"));
    }
}

#[cfg(test)]
mod graph_tests {
    use super::*;

    const DOT: &str = r#"
"aaa-libpng-1.2.59" -> "bbb-beyond-all-reason-1.2988.0" [color = "black"];
"bbb-beyond-all-reason-1.2988.0" -> "ccc-system-path" [color = "black"];
"ccc-system-path" -> "ddd-nixos-system-yggdrasil-26.11" [color = "black"];
"eee-libssh-0.12.2" -> "fff-unit-mautrix-signal.service" [color = "black"];
"fff-unit-mautrix-signal.service" -> "ggg-system-units" [color = "black"];
"ggg-system-units" -> "hhh-etc" [color = "black"];
"hhh-etc" -> "ddd-nixos-system-yggdrasil-26.11" [color = "black"];
"#;

    #[test]
    fn finds_the_toplevel_introducer() {
        let graph = Graph::from_dot(DOT, "ddd-nixos-system-yggdrasil-26.11").unwrap();
        assert_eq!(
            graph.introducer("libpng-1.2.59").as_deref(),
            Some("beyond-all-reason-1.2988.0")
        );
        assert_eq!(
            graph.introducer("libssh-0.12.2").as_deref(),
            Some("unit-mautrix-signal.service")
        );
        assert_eq!(graph.introducer("absent-1.0"), None);
    }
}
