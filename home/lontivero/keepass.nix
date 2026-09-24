{ pkgs, ... }:
let
  # The sync job, as its own package so the systemd unit below and a terminal
  # can reach the same script -- `keepass-sync status` by hand is how you find
  # out what the timer has been doing. The design, and the reason it is bisync
  # rather than a FUSE mount, is written up at the top of the script.
  keepassSync = pkgs.writeShellApplication {
    name = "keepass-sync";
    runtimeInputs = with pkgs; [
      rclone
      coreutils # ls, date, touch, mkdir
      gnugrep # listremotes matching
      libnotify # notify-send, for the conflict toast
      systemd # systemctl, for `status`
    ];
    text = builtins.readFile ./scripts/keepass-sync.sh;
  };
in
{
  # KeePassXC opens the same KDBX 4 databases Keepass2Android writes, so the
  # phone and the laptop share one file and neither needs to know about the
  # other. Google Drive only ever holds the encrypted blob.
  #
  # NB: programs.keepassxc.settings is deliberately left empty. Setting
  # anything there makes home-manager link keepassxc.ini out of the store,
  # read-only, and KeePassXC then reports an access error on every start and
  # can no longer remember its own state -- the last database opened, the
  # window geometry, the browser-integration manifest it installs at startup.
  # For an application whose config is mostly runtime state, letting it own
  # its ini is the honest trade. (home-manager documents this in the option
  # description; see nix-community/home-manager#8257.)
  programs.keepassxc.enable = true;

  # rclone on PATH as well as inside the script: the one-time `rclone config`
  # that authorises Google Drive has to be run by hand, interactively, because
  # it opens a browser for the OAuth consent.
  home.packages = [ pkgs.rclone keepassSync ];

  systemd.user.services.keepass-sync = {
    Unit.Description = "Reconcile the KeePass database with Google Drive";
    Service = {
      Type = "oneshot";
      ExecStart = "${keepassSync}/bin/keepass-sync sync";
    };
  };

  systemd.user.timers.keepass-sync = {
    Unit.Description = "Reconcile the KeePass database with Google Drive";
    Timer = {
      # Ten minutes is a compromise: short enough that the two sides rarely
      # drift far enough apart to both change, long enough not to spin the
      # radio. The window that matters is the one between saving on one
      # device and opening the database on the other.
      OnBootSec = "2m";
      OnUnitActiveSec = "10m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
