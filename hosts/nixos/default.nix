# Desktop host: everything that is true of this machine and no other.
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ../../configuration.nix

    inputs.hosts.nixosModule
  ];

  networking = {
    hostName = "nixos";
    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp4s0.useDHCP = true;
    stevenBlackHosts.enable = true;
  };
}
