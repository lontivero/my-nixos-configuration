{ config, pkgs, ... }:
{
  networking = {
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour. Hostname and per-interface DHCP are set
    # by the host in hosts/<name>/default.nix.
    useDHCP = false;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;

    #extraHosts = let
    #  hostsPath = https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
    #  hostsFile = builtins.fetchurl {
    #    url = hostsPath;
    #    sha256 = "0vad16zbqci3lfpai8yq51kcy0b9xwl147xwvnvy6dspiwxyay2m"; 
    #  };
    #in builtins.readFile "${hostsFile}";
  };
}
