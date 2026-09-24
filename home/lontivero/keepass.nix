{ pkgs, ... }:
let
  # Where the database lives. Syncthing owns this directory; KeePassXC just
  # opens the file in it.
  dir = "Sync/keepass";

  keepassConflicts = pkgs.writeShellApplication {
    name = "keepass-conflicts";
    runtimeInputs = with pkgs; [
      coreutils # cat, mkdir, sort
      libnotify # notify-send
    ];
    text = builtins.readFile ./scripts/keepass-conflicts.sh;
  };
in
{
  # KeePassXC opens the same KDBX 4 databases Keepass2Android writes, so the
  # phone and the laptop share one file and neither needs to know about the
  # other. All that is left is getting the file to both places.
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

  # Syncthing replaces the rclone-and-Google-Drive arrangement this file held
  # first. Drive needs an OAuth client, and rclone's shared one is rate
  # limited and periodically blocked by Google, so the documented fix is to
  # register an application of your own -- a lot of ceremony to move one
  # small file between two devices that are usually in the same room.
  #
  # Syncthing has no account and no authorisation step at all: the phone and
  # this laptop hold each other's public keys, having exchanged them once by
  # QR code, and talk directly. On a LAN they find each other by broadcast; off
  # it they meet through a relay, which only ever sees TLS. Nobody holds a copy
  # of the database but the two devices that use it -- strictly better than
  # trusting Drive with the ciphertext, and much less to set up.
  #
  # The trade, stated plainly: this is peer-to-peer, so both ends have to be
  # awake at the same time for a change to cross. Drive would have taken the
  # phone's write at 3am with the laptop shut. If that turns out to matter,
  # the answer is a third always-on Syncthing node, not a return to Drive.
  services.syncthing = {
    enable = true;

    # NOTHING IS DECLARED BELOW ABOUT DEVICES OR FOLDERS, ON PURPOSE, AND THESE
    # TWO LINES ARE WHAT MAKES THAT SAFE. Both default to true, meaning the
    # module deletes any device or folder it did not declare itself -- so with
    # an empty config and the defaults, every pairing made in the web UI would
    # be wiped on the next restart.
    #
    # The reason not to declare them is this repo being public. A Syncthing
    # device ID is not a secret in the cryptographic sense -- it is a hash of a
    # public key, and pairing still requires both ends to accept -- but anyone
    # holding one can ask the global discovery server where that device is and
    # get back a current IP address. That is a home address, near enough, and
    # it does not belong in a public tree.
    #
    # So: pairing and folder setup are a one-time job in the web UI at
    # http://127.0.0.1:8384. They persist across rebuilds and reboots in
    #
    #   ~/.local/state/syncthing/config.xml
    #
    # untracked, next to key.pem and cert.pem -- which ARE this machine's
    # identity, in the sense that the device ID is a hash of that public key.
    # Keep those two and the pairing survives a reinstall; lose them and the
    # machine comes back as a stranger that has to be paired again.
    #
    # NB: NOT ~/.config/syncthing. Syncthing 2.x moved to the XDG state
    # directory, and this module follows it there for a fresh setup (it falls
    # back to ~/.config/syncthing only if a config.xml is already sitting
    # there from a 1.x install). Worth knowing before backing up the wrong one.
    #
    # See the checklist at the bottom of this file.
    overrideDevices = false;
    overrideFolders = false;

    # Global settings, which are safe to declare: they say nothing about who
    # this machine talks to.
    settings.options = {
      urAccepted = -1; # decline usage reporting rather than be asked later
      crashReportingEnabled = false;
      localAnnounceEnabled = true; # find the phone over the LAN, no relay
      relaysEnabled = true; # ...and still reach it from outside
    };
  };

  # Syncthing writes the losing copy of a conflict next to the winner and then
  # says nothing. This notices and says something; see the script's header for
  # the merge procedure.
  #
  # A path unit rather than a timer: the interesting moment is precisely when
  # the directory changes. PathChanged fires on the directory's mtime, so it
  # also fires on every ordinary save -- which is why the script remembers what
  # it last warned about instead of toasting each time.
  systemd.user.paths.keepass-conflicts = {
    Unit.Description = "Watch the KeePass folder for Syncthing conflict copies";
    Path.PathChanged = "%h/${dir}";
    Install.WantedBy = [ "paths.target" ];
  };

  systemd.user.services.keepass-conflicts = {
    Unit.Description = "Warn about unmerged KeePass conflict copies";
    Service = {
      Type = "oneshot";
      ExecStart = "${keepassConflicts}/bin/keepass-conflicts check";
    };
  };

  home.packages = [ keepassConflicts ];

  # The folder has to exist before the path unit above can watch it, and
  # before Syncthing can be pointed at it in the web UI. home.file is the
  # cheapest way to get home-manager to create a directory; the marker is
  # otherwise meaningless and Syncthing ignores dotfiles it did not write.
  home.file."${dir}/.keep".text = "";

  # ONE-TIME SETUP, none of which can be declared here for the reasons above:
  #
  #   1. Phone: install Syncthing (F-Droid, or "Syncthing-Fork") and
  #      Keepass2Android *Offline* -- the online build's own cloud providers
  #      are not needed any more, and its Drive cache would be a second copy
  #      of the database fighting this one.
  #   2. Laptop: xdg-open http://127.0.0.1:8384
  #      Actions -> Show ID gives a QR code; scan it from the phone to pair.
  #      Accept the incoming device on this side when it appears.
  #   3. Add a folder on this side with path ~/Sync/keepass, share it with the
  #      phone, and in its File Versioning tab choose "Simple" with 10 versions
  #      -- that is the undo for a bad save, and it costs a few MB.
  #   4. Move the .kdbx off Drive into that folder, let it land on the phone,
  #      and point Keepass2Android at the phone-side copy.
}
