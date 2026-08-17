{
  description = "Infrastructure flake for my machines";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-latest-factorio = nixpkgs-master;
    nixpkgs-latest-minecraft = nixpkgs-master;

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omnix = {
      url = "github:Daholli/omnix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    llm-agents-nix = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh-flake = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Support for special cases
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-raspberrypi = {
      url = "github:Daholli/nixos-raspberrypi/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming-edge = {
      url = "github:powerofthe69/nix-gaming-edge";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    titrack = {
      url = "github:Daholli/TiTrack";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ###
    # Niri
    niri = {
      url = "github:YaLTeR/niri";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # The greeter moved out of DankMaterialShell into its own repo -- see the
    # nixosModules.greeter deprecation warning. Provides programs.dms-greeter.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dms-plugin-diskusage = {
      url = "github:alcxyz/DankDiskUsage";
      flake = false;
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ec = {
      url = "github:chojs23/ec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      # Temporarily on sodiboo/niri-flake#1853 until it lands upstream.
      # nixpkgs-unstable removed `libdisplay-info_0_2`, and niri-flake's
      # `libdisplay-info_0_2 ? libdisplay-info` fallback never fires because the
      # attribute still exists as a removal throw -- so the greeter session
      # (dms-greeter-session -> programs.niri.package) fails to evaluate. The PR
      # picks the libdisplay-info matching each niri source's Cargo.lock.
      url = "github:bugeats/niri-flake/7e196a5ce0bf209d3aca844bb31edce5284d6484";
      # url = "github:sodiboo/niri-flake";
      # url = "github:Daholli/niri-flake/1067d35dd18f6a55f79873c944f1427a9eb7caa7"; # for debugging
      inputs = {
        niri-stable.follows = "niri";
        nixpkgs.follows = "nixpkgs";
      };
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gpg-base-conf = {
      url = "github:drduh/config"; # GPG default configuration
      flake = false;
    };

    catppuccin-tide = {
      url = "github:jocelynthode/catppuccin-tide";
      flake = false;
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ###
    # inputs for dev shells
    devenv = {
      url = "github:cachix/devenv";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins.url = "github:nix-community/nix-jetbrains-plugins";

    modern-recorder = {
      # url = "git+ssh://forgejo@git.christophhollizeck.dev/Daholli/Coda-Video-Recorder.git?ref=main";
      url = "git+file:///home/cholli/work/modern-recorder?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
    };

    jbcontext-src = {
      url = "https://download.jetbrains.com/jetbrains-context/builds/v0.9.9.592/context-native-linux-x64-0.9.9.592";
      flake = false;
    };

    ponytail-src = {
      url = "github:DietrichGebert/ponytail/v4.9.0";
      flake = false;
    };
  };
}
