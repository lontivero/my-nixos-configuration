{
  description = "lontivero's NixOS Flake";

  # This is the standard format for flake.nix.
  # `inputs` are the dependencies of the flake,
  # and `outputs` function will return all the build results of the flake.
  # Each item in `inputs` will be passed as a parameter to
  # the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs.
    # The most widely used is `github:owner/name/reference`,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hosts.url = "github:StevenBlack/hosts";
  };

  # `outputs` are all the build result of the flake.
  #
  # A flake can have many use cases and different types of outputs.
  # 
  # parameters in function `outputs` are defined in `inputs` and
  # can be referenced by their names. However, `self` is an exception,
  # this special parameter points to the `outputs` itself(self-reference)
  # 
  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = { self, nixpkgs, home-manager, hosts,... }@inputs:
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
  };
}
