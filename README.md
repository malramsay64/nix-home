# Nix Home

This is the definition of a development environment for working with a wide range of different technologies.
The purpose is to make the setup on a new machine a simple process
and to ensure tools (and their configurations) I find useful are documented as part of an installer.

## Installation

The [Derminate nix installer](https://github.com/DeterminateSystems/nix-installer) is
the recommended way to install nix on a wide range of systems.
This is the approach that I have used to set this up initially.

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Once nix is installed, getting the environment setup and running can be done with the command

```sh
  nix run home-manager -- switch --flake github:malramsay64/nix-home#malcolm
```

## Useful Links

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [mynixos](https://mynixos.com/home-manager) for documentation on each of the configuration options within home manager
- [Nixhub](https://www.nixhub.io/) for a searchable list of all the packages available
