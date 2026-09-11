{
  description = "lontivero's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Only for the dev shell below, which needs a nix newer than the one
    # the release branch ships. The system is never built from this.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Keep home-manager on the same nixpkgs as the system, so both
      # halves of the configuration are built from one package set.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # StevenBlack/hosts: ad and tracker blocking via /etc/hosts.
    hosts.url = "github:StevenBlack/hosts";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, hosts, ... }@inputs:
  let inherit (self) outputs;
  in
  {
    # One entry per machine. Everything a host needs — its hardware scan,
    # hostname and GPU — lives in hosts/<name>/, so this list stays short.
    #
    # NixOS picks the entry matching the machine's hostname, or deploy
    # an explicit one with:
    #   sudo nixos-rebuild switch --flake /path/to/this/directory#nixos
    nixosConfigurations = {
      "nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # specialArgs passes extra arguments to every module below;
        # without it modules only receive lib/config/options/pkgs.
        specialArgs = { inherit inputs outputs; };
        modules = [ ./hosts/nixos ];
      };
    };

    # `nix develop` — a newer nix and nixos-rebuild than the running
    # system's, for when a rebuild needs a feature the system nix lacks.
    # Replaces the old shell.nix, which fetched an unpinned tarball;
    # this tracks nixos-unstable through flake.lock instead.
    devShells.x86_64-linux.default =
      let pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = with pkgs; [
          nixVersions.latest
          nixos-rebuild
        ];
      };
  };
}
