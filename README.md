# Wyrdgard 

<a href="https://nixos.wiki/wiki/Flakes" target="_blank">
	<img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
	<img alt="Built With Snowfall" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>

My all-inclusive nix flake to solve all my problems.


> [!WARNING] 
> Do not just use this repo out of the box since it will not work for your setup (or at least it probably wont work)
> Feel free to copy any parts you find interesting or useful, but I would recommend building your flake up from scratch as it will allow for easier bughunting.

![hyprlock_screenshot](./modules/nixos/desktop/addons/hyprlock/hyprlock_preview.png)


## Repository Overview

- [homes](#homes)
- [lib](#lib)
- [modules](#modules)
- [overlays](#overlays)
- [secrets](#secrets)
- [shells](#shells)
- [systems](#systems)

Starting your nix journey can be daunting and understanding how the whole ecosystem works takes some time. 
For me starting with snowfall-lib was both a blessing and a curse, it took away so many problempoints by being easy, but it also hampered my learning because I never had to do things from scratch and sometimes translating a "normal" flake to a snowfall-lib setup was not trivial.
Luckily for me Jake (the creator of snowfall-lib) was so kind and helped me bugfix and learn how to solve my own Problems.


### homes

The homes folder is home to all your homemanager configuration that is specific to that system (and user) and that system only. 
If you want generic home manager configuration then look into [modules/home](modules/home/README.md).

- home/system/user@hostname syntax 

I dont really use this besides for testing out some apps, most of the things get turned into generic modules so I can eventually reuse them later.

For more extensive explainations checkout [snowfall-lib/homes](https://snowfall.org/guides/lib/homes/)!

### lib

- extending lib
- any things defined here can be accessed vial `inherit (lib.${namespace})`

Mine is straight ripped from [here](https://github.com/jakehamilton/config/blob/main/lib/module/default.nix), as I have not found much use for this outside of these options, maybe at some point.

For more extensive explainations checkout [snowfall-lib/lib](https://snowfall.org/guides/lib/library/)!

### [modules](./modules/README.md)

This is the most interesting section of the flake, here I (and other users of snowfall-lib) define the packages that are available to your configuration.
there are 3 main categories

- nixos     `general system packages`
- home      `general homemanager packages`
- darwin    `general mac packages (tho at this point in time I do not have a mac)`

Most of my configuration happens in this section and this is also where the different snowfall-lib repos diverge, some aspects are still fairly close to Jakes as that is what I started with, but some areas are more mature and now more my own style.
For more concrete information abotu my system specific setup read [here](/modules/nixos/README.md).

For more extensive explainations checkout [snowfall-lib/modules](https://snowfall.org/guides/lib/homes/)!

### [overlays](./overlays/README.md)

- overlays provided by this flake

For more extensive explainations checkout [snowfall-lib/overlays](https://snowfall.org/guides/lib/overlays/)!

### secrets

- secrets used currently only one file

> [!IMPORTANT]
> This uses [sops-nix](https://github.com/Mic92/sops-nix) to encrypt sensitive information you need in your flake, never have secrets or password unencrypted in your repo, not even if it is private


### [shells](./shells/README.md)

This is also fairly interesting and a section I have not delved in too much, currently I only have a rust flake for [screeps-rust](https://github.com/Daholli/screeps-rust) in here.
I think thi sis great to have quick access to a out of the box dev shell, but generally you probably want a project specific flake.

You can access these flakes either using `self#rust` or in my case `github:Daholli/nixos-config#rust`.


For more extensive explainations checkout [snowfall-lib/shells](https://snowfall.org/guides/lib/shells/)!

### systems

- all the systems that can be built with the flake
- systems/system/hostname syntax

This is the heart piece of the flake, this is what is being targeted if you call `nixos-rebuild switch --flake .#<hostname>` I try to only have very system specific config in here and try to cover all the other things in the [generic part of the flake](/modules/nixos/README.md).
If you want to start piecing together how my config works this is where you would start. 

For more extensive explainations checkout [snowfall-lib/systems](https://snowfall.org/guides/lib/systemns/)!

<br>
<br>

## inspirations and thanks

Most of this config draws inspiration from this config:
[https://github.com/jakehamilton/config](https://github.com/jakehamilton/config)


