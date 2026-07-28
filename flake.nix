{
  description = "Home Manager configuration of malcolm";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vercel-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
    superpowers-skills = {
      url = "github:awdemos/opencode-superpowers";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      vercel-skills,
      superpowers-skills,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        system = system;
        config = {
          allowUnfree = true;
        };
      };
      pkgs-stable = import nixpkgs-stable {
        system = system;
        config = {
          allowUnfree = true;
        };
      };
      lib = pkgs.lib;

      # Each entry: { src = <flake-input>; dir = "path/to/skills/within/repo"; }
      skillSources = {
        "vercel-labs"."skills" = {
          src = vercel-skills;
          dir = "skills";
        };
        "awdemos"."opencode-superpowers" = {
          src = superpowers-skills;
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

    in
    {

      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./shared.nix
          ./home.nix
          ./skills.nix
          ./pi.nix
        ];

        extraSpecialArgs = {
          inherit availableSkills pkgs-stable;
          defaultBrowser = "zen";
          profile = "home";
          user = {
            username = "malcolm";
            name = "Malcolm Ramsay";
            home = "/home/malcolm";
            email = "m@malramsay.com";
          };
        };
      };
      homeConfigurations."work" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./shared.nix
          ./work.nix
          ./skills.nix
          ./pi.nix
        ];

        extraSpecialArgs = {
          inherit availableSkills pkgs-stable;
          defaultBrowser = "wslview";
          profile = "work";
          user = {
            username = "malcolm";
            name = "Malcolm Ramsay";
            home = "/home/malcolm";
            email = "malcolm.ramsay@tiimely.com";
          };
        };
      };
    };
}
