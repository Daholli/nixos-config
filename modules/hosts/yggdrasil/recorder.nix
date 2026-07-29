topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      # Native single-node k3s + Postgres + rustfs (S3) + Redis for modern-recorder,
      # replacing the devenv/k3d/podman-nested dev loop. k3s talks to Postgres over
      # a unix socket and rustfs/Redis bind 127.0.0.1 only -- no ports need to be
      # opened on the host firewall for these to talk to each other.
      imports = [ "${inputs.modern-recorder}/nix/profiles/single-node.nix" ];

      # Service secrets (#62) + user/admin secrets (#15 prep, rustfs root key +
      # coda_recorder password) -- generated via modern-recorder's
      # generate-recorder-secrets.sh, recipients *primary and *yggdrasil in
      # .sops.yaml. Rotate with `sops secrets/secrets-recorder{,-users}.yaml`.
      services.recorderSecretsFile = ../../../secrets/secrets-recorder.yaml;
      services.recorderUserSecretsFile = ../../../secrets/secrets-recorder-users.yaml;
      # gRPC mTLS internal CA + per-service leaf certs (#211), generated via
      # modern-recorder's generate-recorder-mtls-ca.sh, same recipients as above.
      # Rotate with `sops secrets/secrets-recorder-mtls.yaml`.
      services.recorderMtlsSecretsFile = ../../../secrets/secrets-recorder-mtls.yaml;

      # rustfs has its own built-in web console (services.rustfs.consoleAddress,
      # loopback-only) -- no separate container needed, unlike garage-web-ui
      # (upstream-unmaintained, no nix package) which this replaces.

      # recorder-operator loads freshly built images via `k3s ctr images import`
      # instead of a registry push -- let cholli run that one command as root
      # without a password so the devenv image-build loop doesn't need sudo -S.
      security.sudo.extraRules = [
        {
          users = [ topLevel.config.flake.meta.users.cholli.username ];
          commands = [
            {
              command = "/run/current-system/sw/bin/k3s ctr images import *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      # Per-service Postgres roles (pg_hba TCP rules) and the kubeconfig group-
      # readable copy now live in modern-recorder's nix/modules/pg.nix and
      # nix/modules/k3s.nix (imported via profiles/single-node.nix above), so any
      # collaborator's own host gets both without personal, OS-user-specific setup.

      # libvirtd/QEMU host for disposable test VMs, driven by an external
      # terraform project via the dmacvicar/libvirt provider (qemu:///system
      # over the local unix socket). cholli's own membership in "libvirtd"
      # grants that socket access -- no extra polkit rules needed.
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };
      users.users.cholli.extraGroups = [ "libvirtd" ];

      # Single source of truth for cholli's SSH key, readable by terraform's
      # cloud-init user_data so test VMs accept the same key as the host
      # (topLevel.config.flake.meta.users.cholli.authorizedKeys).
      environment.etc."ssh-keys/cholli.pub".text =
        builtins.concatStringsSep "\n" topLevel.config.flake.meta.users.cholli.authorizedKeys;
    };
}
