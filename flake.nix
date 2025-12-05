{
  description = "Home Manager configuration of malcolm";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
          system = system;
          config = {
            allowUnfree = true;
          };
        };
    in {
      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          user = {
            username = "malcolm";
            name = "Malcolm Ramsay";
            home = "/home/malcolm";
            email = "m@malramsay.com";
          };
          pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
          };
        };
      };
      homeConfigurations."work" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {          
          user = {
            username = "malcolm";
            name = "Malcolm Ramsay";
            home = "/home/malcolm";
            email = "malcolm.ramsay@tiimely.com";
          };
          pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
          };
        };
      };
    };
}
