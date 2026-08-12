topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs = {
        config.allowUnfree = true;
      };

      # Enable binfmt emulation.
      # boot.binfmt.emulatedSystems = [
      #   "aarch64-linux"
      # ];
      #
      programs.nix-ld.enable = true;

      environment.systemPackages =
        with pkgs;
        let
          inherit (pkgs.jetbrains) rust-rover;

          # nixpkgs' rider indexes the bundled (and later deleted)
          # plugins/remote-dev-server/selfcontained/lib during autoPatchelf, so
          # the ReSharperHost binaries end up with a dangling /build/... RUNPATH
          # instead of one pointing at libstdc++. The backend then dies with
          # "libstdc++.so.6: cannot open shared object file", which Rider
          # surfaces as "contact Rider support". Re-add the runpath in a phase
          # that runs *after* fixupPhase — postFixup runs before autoPatchelf,
          # which would overwrite it again.
          rider = pkgs.jetbrains.rider.overrideAttrs (old: {
            postPhases = (old.postPhases or [ ]) ++ [ "fixReSharperHostRunpath" ];

            fixReSharperHostRunpath = ''
              for f in $out/rider/lib/ReSharperHost/linux-*/*; do
                [ -f "$f" ] && [ -x "$f" ] || continue
                if patchelf --print-needed "$f" 2>/dev/null | grep -q '^libstdc++\.so\.6$'; then
                  echo "fixing libstdc++ runpath: $f"
                  patchelf --add-rpath ${lib.getLib pkgs.stdenv.cc.cc}/lib "$f"
                fi
              done
            '';
          });

          plugins =
            inputs.nix-jetbrains-plugins.lib.pluginsForIdeWith
              {
                applyPluginOverrides = true;
              }
              pkgs
              rust-rover
              [
                "com.intellij.plugins.watcher"
                "com.github.copilot"
                "com.intellij.ml.llm"
                "org.jetbrains.junie"
              ];
        in
        [
          teams-for-linux

          obsidian
          diebahn

          termscp
          nixpkgs-review

          postman
          vlc
          ffmpeg
          azure-cli
          onlyoffice-desktopeditors

          jetbrains.rust-rover
          (pkgs.jetbrains.plugins.addPlugins jetbrains.rust-rover (lib.attrValues plugins))
          rider

          rocmPackages.amdsmi

          # osu-lazer-bin

          piper
          ghc # for maths

          inputs.omnix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

      # services.resolved.enable = lib.mkForce false;
      services.ratbagd.enable = true;
      services.ollama = {
        enable = false;
        package = pkgs.ollama-rocm;

        loadModels = [
        ];

        environmentVariables = {
          OLLAMA_ORIGINS = "*";
        };
      };

      environment.pathsToLink = [ "/libexec" ];

      programs.ssh.extraConfig = ''
        AddressFamily inet
      '';

      imports = with topLevel.config.flake.modules.nixos; [
        inputs.nixos-hardware.nixosModules.common-cpu-amd
        inputs.nixos-hardware.nixosModules.common-pc
        inputs.nixos-hardware.nixosModules.common-pc-ssd

        # System modules
        base
        dev
        desktop
        games

        # hardware
        audio
        bluetooth
        amdgpu

        # desktops
        # hyprland
        niri

        # apps
        _1password
        kdeconnect

        # Users
        cholli
        root
      ];

      sops.secrets = {
        "remotebuild/private-key" = {
          sopsFile = ../../../secrets/secrets.yaml;
          owner = "cholli";
          mode = "0400";
        };

        "cholli/private-key" = {
          sopsFile = ../../../secrets/secrets.yaml;
          mode = "0600";
        };
      };

      fileSystems."/mnt/pi_share" = {
        device = "cholli@192.168.178.2:/storage/cholli/";
        fsType = "sshfs";

        options = [
          # Filesystem options
          "allow_other" # for non-root access
          "_netdev" # this is a network fs
          "x-systemd.automount" # mount on demand

          # SSH options
          "reconnect" # handle connection drops
          "ServerAliveInterval=15" # keep connections alive
          "IdentityFile=${config.sops.secrets."cholli/private-key".path}"
        ];
      };

      nix = {
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
        buildMachines = [
          {
            hostName = "nixberry";
            sshUser = "remotebuild";
            sshKey = config.sops.secrets."remotebuild/private-key".path;
            systems = [ "aarch64-linux" ];
            protocol = "ssh-ng";

            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "kvm"
            ];
          }
        ];
      };
    };
}
