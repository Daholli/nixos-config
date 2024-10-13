# System configuration

## apps

These contain specialized configurations some simple some more complex to enable programs and everything around them.
This section also has a subsection `cli-apps` which is exclusively for apps that live in your terminal.

## [archetypes](./archetypes/README.md)

This section contains configurations that enable whole system types at once, check out the more in depth Readme in that section

Planned archetypes are:
- gaming (this is mostly fleshed out since I use it on my main machine)
- wsl
- pi
- minimal-server
- github runner?


## [desktop](./desktop/README.md)

This section contains everything related to GUI.
currently I am using Hyprland, but I was using more or less out of the box KDE for a long time and was very happy with it.
It also has a `addons` section where I plan to put all configurations for things of the hyprland ecosystem and bars such as waybar / ags (in the future).

## security

This has some of the configuration you need for your system to run properly, gpg has the yubikey configuration, the keyring is well a keyring, so that your computer can access the TPM, and also [sops-nix](https://github.com/Mic92/sops-nix) which I would recommend to setup for critical information.

## services

This section is fairly empty, but will be filled up when I start with the server configs.

## [submodules](./submodules/README.md)

This is the smaller archetypes section, just to combine some aspects that are never used alone into one package, such as the basic one that activates all the mandatory things I don't want to write out every time. 

## system

This section is home to all of the low level system related configuration, it contains sections for your hardware, keyboard layouts what boot attributes to set, and which fonts to install.

## tools

This section could also be part of the cli-apps section but I want to have more system critical things here e.g Git and direnv both amazing tools that deserve a special spot in this config.

## user

Here you define the user, or I guess users if you have more people using this system, I will think about multi user systems when I need to :D
 

