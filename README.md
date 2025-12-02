# Welcome to my infrastructure configuration
My configuration is based on [Dendritic Nix](https://dendrix.oeiuwq.com/Dendritic.html#dendritic-nix)
and was heavily inspired by [github:drupol/infra](https://github.com/drupol/infra) including taking some parts ad-verbatim.

## How does it work?
The two main aspects are [github:vic/import-tree](https://github.com/vic/import-tree) and [flake-parts](https://flake.parts/)
```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```
this lets us define our starting point in another file. In this case this would be [host-machines](./modules/flake-parts/host-machines.nix)
There are many different approaches to this but I found drupols approach of parsing the module name interesting so I wanted to use it aswell.
I extended mine by filtering my rpi configurations to be a bit different.

### defining hosts
```nix
    flake.modules.nixos."hosts/yggdrasil" = { inputs, ... }: {
      ...

      # here comes the fun part:
      imports = with topLevel.config.flake.modules.nixos; [
        # this is where you add your self named modules that you want to use for this host
        # e.g
        base
        cholli
      ];
      # this will now evaluate thos modules and enable everything set up in them
    };
```

### defining modules
What I quite like is that there is no needed structure in your modules folder. You can reorganize all you want,
all that matters is that your modules are name exactly how you import them.
```nix
  # There are two types of modules you probably want to choose from
  flake.modules.nixos."<your name here>" # nixos base configuration

  flake.modules.home-manager."<your name here>" # home-manager configuration

  # additionally what I like to do is in your home modules make sure that the appropriate system module is enabled before you do something
  home.file = lib.mkIf osConfig.programs."<program name>".enable { ... };
```

## WM of choice
A friend of mine introduced me to niri and I really like it configuration of that can be found under [niri.nix](./modules/desktop/niri.nix)
I still use [hyprpaper](./modules/desktop/addons/hyprpaper.nix), and [hyprlock](./modules/desktop/addons/hyprlock.nix) because I was previously using hyprland and the still work perfectly fine.
My bar of choice is [waybar](./modules/desktop/addons/waybar.nix) it is very minimalistic, and my current runner is fuzzel with I just use with a catppuccin theme.
