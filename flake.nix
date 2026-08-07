# /etc/nixos/flake.nix
{
  description = "NixOS home-ops";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # darwin
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Secret management
    sops-nix.url = "github:Mic92/sops-nix";

    # MicroVM
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };

  };
  outputs = inputs@{ self, nixpkgs, nix-darwin, unstable, sops-nix, microvm
    , home-manager, nixvim, ... }: {

      # NixOS configuration for B660-i5-13600 (host)
      nixosConfigurations.b660-i5-13600 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";

        specialArgs = {
          pkgs-unstable = import unstable {
            config.allowUnfree = true;
            inherit system;
          };
        };

        modules = [
          sops-nix.nixosModules.sops
          microvm.nixosModules.host
          ./hosts/b660-i5-13600
          ./profiles
          ./modules
        ];
      };
      # Laptop (dev machine)
      nixosConfigurations.dell-i5-7300U = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/dell-i5-7300U
          ./profiles/workstation.nix
          home-manager.nixosModules.home-manager
          {
            users.users.sebastiaan.home = "/home/sebastiaan";
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              sharedModules = [ nixvim.homeManagerModules.nixvim ];
              users = { sebastiaan = import ./home/modules/default.nix; };
            };
          }
        ];
      };

      # Laptop (macbook)
      darwinConfigurations.MacBook-Pro-van-Sebastiaan =
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs = { config.allowUnfree = true; }; }
            ./hosts/macbook-m5
            home-manager.darwinModules.home-manager
            {
              users.users.sebastiaan.home = "/Users/sebastiaan";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                  pkgs-unstable = import unstable {
                    config.allowUnfree = true;
                    system = "aarch64-darwin";
                  };
                };
                sharedModules = [ nixvim.homeModules.nixvim ];
                users = { sebastiaan = import ./home/modules/default.nix; };
              };
            }
          ];
        };

      devShells.x86_64-linux.default = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.mkShell {
        packages = with pkgs; [
          kubernetes-helm
          kubeconform
          yamllint
          yq-go
        ];
      };

      devShells.aarch64-darwin.default = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
      in pkgs.mkShell {
        packages = with pkgs; [
          kubernetes-helm
          kubeconform
          yamllint
          yq-go
        ];
      };

    };
}
