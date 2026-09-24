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

    # Syncthing, which home/lontivero/keepass.nix runs as a user service to
    # keep the KeePass database in step with the phone. The firewall is on by
    # default in NixOS and these are the ports Syncthing needs opened inbound:
    #
    #   22000/tcp  the sync protocol itself
    #   22000/udp  the same over QUIC, which is what it prefers on wifi
    #   21027/udp  local discovery -- the broadcasts other devices send to
    #              announce themselves on the LAN
    #
    # Without 21027 the two ends never see each other at home and fall back to
    # a public relay: still encrypted, still correct, but slower and routed
    # through a stranger for no reason. Without 22000 inbound only outbound
    # connections work, so whether they connect at all comes down to which
    # side dials first.
    #
    # NB: the system-level services.syncthing has an `openDefaultPorts` option
    # that does exactly this. It is not usable here -- Syncthing is declared
    # through home-manager, in the user's own module, so this is the
    # system-level counterpart, written out by hand.
    firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 21027 ];
    };

    #extraHosts = let
    #  hostsPath = https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
    #  hostsFile = builtins.fetchurl {
    #    url = hostsPath;
    #    sha256 = "0vad16zbqci3lfpai8yq51kcy0b9xwl147xwvnvy6dspiwxyay2m"; 
    #  };
    #in builtins.readFile "${hostsFile}";
  };
}
