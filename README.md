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

## Upgrading

Run `upgrade-everything` to update the tools and activate the current Home Manager
profile. Both profiles upgrade `uv` tools, upgrade the Determinate Nix installation
when present, update the flake inputs in `flake.lock`, and run `home-manager switch`
for the active profile. It also updates Pi-managed extensions and clears the
configured one-shot MCP servers' npm/uv caches so they fetch fresh versions when
next launched. The pinned `pi-subagents` version remains pinned. The `work` profile
also upgrades Ubuntu packages with `apt`, Windows packages with `winget.exe`, and opens
the Windows Update settings page (from WSL). Windows Update installation and any
required restart remain interactive. Failures are reported after the remaining
upgrade steps have been attempted.

The command expects this checkout at `~/projects/nix-home` by default. If it is
elsewhere, set `NIX_HOME_FLAKE` when running it, for example:

```sh
NIX_HOME_FLAKE="$HOME/src/nix-home" upgrade-everything
```

Updating flake inputs changes `flake.lock` in the checkout; review and commit that
change when appropriate.

## Useful Links

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [mynixos](https://mynixos.com/home-manager) for documentation on each of the configuration options within home manager
- [Nixhub](https://www.nixhub.io/) for a searchable list of all the packages available
