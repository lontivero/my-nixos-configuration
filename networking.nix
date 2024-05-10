{ config, pkgs, ... }:
{
  networking = {
    hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp4s0.useDHCP = true;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;

    extraHosts = let
      hostsPath = https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
      hostsFile = builtins.fetchurl {
        url = hostsPath;
        sha256 = "0mn1xr6ainm2vhsvnqxp3j3843gn1pblyf6fw56yc95qa2qw71qa"; 
      };
    in builtins.readFile "${hostsFile}";
  };
}
