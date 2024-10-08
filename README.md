# Wyrdgard 

<a href="https://nixos.wiki/wiki/Flakes" target="_blank">
	<img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
	<img alt="Built With Snowfall" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>

My all-inclusive nix flake to solve all my problems.

[ToC]

# Repository Overview

## homes

- user@system syntax
- home manager config possible

## lib

- extending lib

## modules

- nixos
- home
- darwin

[Different modules explained](./modules/README.md)

## overlays

- overlays provided byt this flake
[Overlays](./overlays/README.md)

## secrets

- secrets used currently only one file
## shells

[Shells](./shells/README.md)
## systems

- all the systems that can be built with the flake


<br>
<br>

## inspirations and thanks

Most of this config draws inspiration from this config:
[https://github.com/jakehamilton/config](https://github.com/jakehamilton/config)


# NixOs config

## Archetypes

### Gaming

This archetype installs Steam and the Prismlauncher, a graphical user interface (KDE) and some other basic functionality.
I want to look into also setting up some factorio configs declarative later. Maybe setup Lutris to allow for some other games aswell.
Currently Steam with proton is working amazingly.

I want to change the way that the GUI is setup so I can later choose a display manager I want to use something like hyperland maybe, since i3 was what I always used before.

### Development

This is mainly just reading up on direnv and making sure I learn how to use cargo under nix so I can start my journey to learn rust again.Also getting this to work means working more on my [nixvim derivative](https://github.com/Daholli/nixvim).

### Workstation

Mainly for Office or daily stuff, libre Office, Pdf readers and the likes come to mind, also thinking about what to exclude from KDE that I dont really need installed to make sure that the installtion size stays somewhat small.

### Server

I want to try setting up a DIY NAS at home using nix and maybe a rasberry pie but there is no real concrete plan for now.

## Security

I want to learn about what (besides not being a monkey) I can to to make my system more secure. I have a lot to learn here.

## Deployment

How do I deplo my config onto new systems, and how do I safely transmit my signing key for git to other hosts

## Backups

I saw that there is a onedrive version for linux, but I feel like that is not a good solution, I should look into [syncthing](https://syncthing.net) as this one looks really interesting, but I don't want to start this until I understood all of the implications.


