{
  description = "Home Manager configuration of malcolm";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers-skills = {
      url = "github:awdemos/opencode-superpowers";
      flake = false;
    };
    pymc-modeling-skills = {
      url = "github:pymc-labs/pymc-modeling";
      flake = false;
    };
    mitos = {
      url = "github:mitos-editor/mitos/v0.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # These Rust builds (aws-lc-sys, zstd-sys) probe system libraries through
      # pkg-config without declaring them, so add them explicitly.
      withSysDeps =
        pkgs: deps: drv:
        drv.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
          buildInputs = (old.buildInputs or [ ]) ++ deps;
        });

      overlay = final: prev: {
        mitos = withSysDeps final [ final.aws-lc ] inputs.mitos.packages.${system}.default;
        zizmor = withSysDeps final [ final.aws-lc ] prev.zizmor;
        pqrs = withSysDeps final [ final.zstd ] prev.pqrs;
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };

      # Each entry: { src = <flake-input>; dir = "path/to/skills/within/repo"; }
      skillSources = {
        "awdemos"."opencode-superpowers" = {
          src = inputs.superpowers-skills;
          dir = "skills";
        };
        "pymc-labs"."pymc-modeling" = {
          src = inputs.pymc-modeling-skills;
          dir = "skills";
        };
      };

      # Build nested attrset: org.repo.skillName = { name; path; }
      availableSkills = builtins.mapAttrs (
        _: repos:
        builtins.mapAttrs (
          _:
          { src, dir }:
          let
            entries = builtins.readDir "${src}/${dir}";
            # readDir propagates string context from its path arg onto attrset keys;
            # strip it so skill names can be used as plain strings downstream.
            dirs = map builtins.unsafeDiscardStringContext (
              builtins.attrNames (lib.filterAttrs (_: type: type == "directory") entries)
            );
          in
          lib.genAttrs dirs (name: {
            inherit name;
            path = /. + builtins.unsafeDiscardStringContext "${src}/${dir}/${name}";
          })
        ) repos
      ) skillSources;

      mkHome =
        { profile, email }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./shared.nix
            ./${profile}.nix
            ./skills.nix
            ./pi.nix
            ./zellij.nix
          ];
          extraSpecialArgs = {
            inherit availableSkills profile;
            user = {
              username = "malcolm";
              name = "Malcolm Ramsay";
              home = "/home/malcolm";
              inherit email;
            };
          };
        };
    in
    {
      homeConfigurations = {
        home = mkHome {
          profile = "home";
          email = "m@malramsay.com";
        };
        work = mkHome {
          profile = "work";
          email = "malcolm.ramsay@tiimely.com";
        };
      };
    };
}
