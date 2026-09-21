{ ... }:

let
  wasabiUser = "user";
  wasabiFile = "~/.ssh/wasabi-server.key";
in
{
  programs.ssh = {
    enable = true;

    # 26.05 replaced the typed options (forwardAgent, matchBlocks, ...) with
    # freeform ssh_config blocks keyed by Host pattern, spelled with upstream
    # directive names. The module always renders the "*" block last, so the
    # host blocks below still win -- ssh_config takes the FIRST value it sees
    # for a keyword.
    #
    # enableDefaultConfig would prepend home-manager's own "*" defaults. The
    # ones worth having are set explicitly below; the rest of them (Compression
    # no, ServerAliveCountMax 3, UserKnownHostsFile ~/.ssh/known_hosts,
    # ControlPersist no) only restate OpenSSH's own defaults.
    enableDefaultConfig = false;

    settings = {
      "wasabi-production" = {
        HostName = "209.38.41.34";
        User = wasabiUser;
        IdentityFile = wasabiFile;
        IdentitiesOnly = true;
      };
      "wasabi-testing" = {
        HostName = "87.120.84.36";
        User = wasabiUser;
        IdentityFile = wasabiFile;
        IdentitiesOnly = true;
      };
      "github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/id_rsa";
        IdentitiesOnly = true;
      };
      "bitcoin-full-node.org.ar" = {
        IdentityFile = "~/.ssh/bitcoin-full-node.org.ar";
      };

      "*" = {
        ForwardAgent = true;
        HashKnownHosts = true;
        ServerAliveInterval = 60;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%h:%p";
        IdentitiesOnly = true;
        # NB: this used to be dead. It was set in extraConfig, which landed
        # BELOW home-manager's default `AddKeysToAgent no` in the same "*"
        # block, so the default won. Now it actually takes effect.
        AddKeysToAgent = "yes";
      };
    };
  };
}
