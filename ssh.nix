{ config, pkgs, ... }:

let
  lib = pkgs.stdenv.lib;
  wasabiUser = "user";
  wasabiFile = "~/.ssh/wasabi-server.key";
in  
{
  home-manager.users.lontivero.programs.ssh = {
    enable = true;
    forwardAgent = true;
    hashKnownHosts = true;
    serverAliveInterval=60;
    controlMaster = "auto";
    controlPath = "~/.ssh/master-%r@%h:%p";
    matchBlocks = {
      "wasabi-production" = {
        hostname = "209.38.41.34";
        user = wasabiUser;
        identityFile =wasabiFile;
        identitiesOnly = true;
      };
      "wasabi-testing" = {
        hostname = "87.120.84.36";
        user = wasabiUser;
        identityFile =wasabiFile;
        identitiesOnly = true;
      };
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/id_rsa";
        identitiesOnly = true;
      };
      "bitcoin-full-node.org.ar" = {
        identityFile = "~/.ssh/bitcoin-full-node.org.ar";
      };
    };
    extraConfig = ''
      IdentitiesOnly yes 
      AddKeysToAgent yes
    '';
  };
}


