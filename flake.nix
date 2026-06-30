{
  description = "Home Manager configuration of malcolm";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vercel-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, vercel-skills, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
          system = system;
          config = {
            allowUnfree = true;
          };
        };

      # Each entry: { src = <flake-input>; dir = "path/to/skills/within/repo"; }
      skillSources = {
        "vercel-labs"."skills" = { src = vercel-skills; dir = "skills"; };
      };

      # Build nested attrset: org.repo.skillName = path-to-skill-dir
      availableSkills =
        builtins.mapAttrs (org: repos:
          builtins.mapAttrs (_: { src, dir }:
            builtins.mapAttrs
              (name: _: "${src}/${dir}/${name}")
              (builtins.filterAttrs (_: type: type == "directory") (builtins.readDir "${src}/${dir}"))
          ) repos
        ) skillSources;

    in {

      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./shared.nix ./home.nix ./skills.nix ];

        extraSpecialArgs = {
          inherit availableSkills;
          defaultBrowser = "zen";
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

        modules = [ ./shared.nix ./work.nix ./skills.nix ];

        extraSpecialArgs = {
          inherit availableSkills;
          defaultBrowser = "wslview";
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
