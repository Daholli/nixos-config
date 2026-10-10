{
  # Factorio's authenticated tarballs are fetched client-side with a token only cholli can read,
  # then added to the store by hash, so the nix-daemon (and remote builders) never see it.
  flake.modules.nixos.factorio-prefetch =
    { config, pkgs, ... }:
    let
      secretOpts = {
        sopsFile = ../../secrets/secrets-yggdrasil.yaml;
        owner = "cholli";
        mode = "0400";
      };

      authSrcs = pkgs.writeText "factorio-auth-srcs.nix" ''
        nixpkgs:
        let
          systems = [ "x86_64-linux" "aarch64-linux" ];
          attrs = [ "factorio" "factorio-experimental" "factorio-space-age" "factorio-space-age-experimental" ];
          srcOf = pkgs: attr:
            let
              s = pkgs.''${attr}.src;
              v = if builtins.elem "NIX_FACTORIO_TOKEN" (s.impureEnvVars or [ ])
                then [ { inherit (s) name; out = s.outPath; url = builtins.head s.urls; } ]
                else [ ];
              r = builtins.tryEval (builtins.deepSeq v v);
            in
            if r.success then r.value else [ ];
        in
        builtins.concatMap (system:
          let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          in builtins.concatMap (srcOf pkgs) attrs
        ) systems
      '';

      factorio-prefetch = pkgs.writeShellApplication {
        name = "factorio-prefetch";
        runtimeInputs = with pkgs; [
          curl
          jq
        ];
        text = ''
          # usage: factorio-prefetch [<PR number> | <nixpkgs path> | <flake ref>], default: current dir
          ref=''${1:-.}
          if [[ "$ref" =~ ^[0-9]+$ ]]; then
            ref="github:NixOS/nixpkgs/pull/$ref/head"
          fi
          if [[ -d "$ref" ]]; then
            nixpkgs=$(realpath "$ref")
          else
            nixpkgs=$(nix flake prefetch --json "$ref" | jq -r .storePath)
          fi
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          nix eval --json --impure --expr "import ${authSrcs} $nixpkgs" \
            | jq -c 'unique_by(.out)[]' \
            | {
              failed=0
              while read -r src; do
                name=$(jq -r .name <<<"$src")
                url=$(jq -r .url <<<"$src")
                out=$(jq -r .out <<<"$src")
                if nix-store --check-validity "$out" 2>/dev/null; then
                  echo "present: $out"
                  continue
                fi
                echo "fetching: $name"
                if ! curl -fL --progress-bar --get \
                  --data-urlencode "username@${config.sops.secrets."factorio/username".path}" \
                  --data-urlencode "token@${config.sops.secrets."factorio/token".path}" \
                  -o "$tmp/$name" "$url"; then
                  # 403 means the account does not own this release (e.g. Space Age)
                  echo "failed: $name" >&2
                  rm -f "$tmp/$name"
                  failed=1
                  continue
                fi
                added=$(nix-store --add-fixed sha256 "$tmp/$name")
                rm "$tmp/$name"
                if [[ "$added" != "$out" ]]; then
                  echo "hash mismatch for $name: got $added, expected $out" >&2
                  exit 1
                fi
                echo "added: $out"
              done
              exit "$failed"
            }
        '';
      };
    in
    {
      sops.secrets."factorio/username" = secretOpts;
      sops.secrets."factorio/token" = secretOpts;

      users.users.cholli.packages = [ factorio-prefetch ];
    };
}
