#!/usr/bin/env bash
# Bump the jbcontext-src flake input (and the version in jbcontext-module.nix)
# to the latest JetBrains Context release. Resolves "latest" like the official
# installer: https://download.jetbrains.com/jetbrains-context/install.sh
#
# Usage: modules/dev/update-jbcontext.sh [VERSION]

set -euo pipefail
cd "$(dirname "$0")/../.."

new=${1:-$(curl -fsSL -H "Cache-Control: no-cache" --max-time 30 \
  https://download.jetbrains.com/jetbrains-context/release/version.txt | tr -d '[:space:]')}
[[ $new =~ ^[0-9]+(\.[0-9]+)*$ ]] || {
  echo "invalid version: '$new'" >&2
  exit 1
}

old=$(grep -oP 'jetbrains-context/builds/v\K[0-9.]+(?=/)' flake.nix)
[[ $old == "$new" ]] && {
  echo "jbcontext already at $new"
  exit 0
}

sed -i "s/${old//./\\.}/$new/g" flake.nix modules/dev/jbcontext-module.nix
nix flake update jbcontext-src
echo "jbcontext: $old -> $new"
