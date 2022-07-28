{ config, pkgs, ... }:

let
  lib = pkgs.stdenv.lib;
  zkUser = "user";
  zkJumpProxy = "zk-jump-proxy";
  zkIdentityFile = "~/.ssh/wasabi-server.key";
in  
{
  home-manager.users.lontivero.programs.ssh = {
    enable = true;
    forwardAgent = false;
    hashKnownHosts = true;
    serverAliveInterval=60;
    controlMaster = "auto";
    controlPath = "~/.ssh/master-%r@%h:%p";
#    knownHosts = [
#      {
#        hostNames = ["github.com" "192.30.253.113"];
#	publickKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
#      }
#    ];
    matchBlocks = {
      "zk-jump-proxy" = {
        hostname = "167.71.65.241";
        user = "lucas";
        port = 14567;
        identityFile = zkIdentityFile;
      };
      "zk-production" = {
        hostname = "178.62.244.102";
        user = zkUser;
        proxyJump = zkJumpProxy;
        identityFile =zkIdentityFile;
        identitiesOnly = true;
      };
      "zk-testing" = {
        hostname = "206.189.96.26";
        user = zkUser;
        proxyJump = zkJumpProxy;
        identityFile = zkIdentityFile;
        identitiesOnly = true;
      };
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/id_rsa";
        identitiesOnly = true;
      };
      "github-bitcoinitax" = {
        hostname = "github.com";
        identityFile = "~/.ssh/bitcoinitax";
        identitiesOnly = true;
      };
      "bitcoin-full-node.org.ar" = {
        identityFile = "~/.ssh/bitcoin-full-node.org.ar";
      };
    };
    extraConfig = ''
      identitiesOnly yes 
      AddKeysToAgent yes
    '';
  };
}


