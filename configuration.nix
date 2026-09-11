# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, outputs, lib, pkgs, ... }:
let
  # Where the NixOS modules collect the .desktop files for every enabled
  # session -- share/wayland-sessions for Hyprland, share/xsessions for i3.
  # lightdm found these on its own; greetd has to be pointed at them.
  sessionDesktops = config.services.displayManager.sessionData.desktops;
in
{
  # Shared system configuration. Hardware, hostname and anything else
  # specific to a single machine lives in hosts/<name>/ instead.
  imports =
    [ inputs.home-manager.nixosModules.home-manager
      ./networking.nix
    ];

  nixpkgs.config.allowUnfree = true;

  # Manage the virtualisation services

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Plymouth boot splash screen
  boot.plymouth.enable = true;

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # do not install what I dont want
  # services.gnome.core-utilities.enable = false;

  #### Login manager ####################################################
  #
  # greetd runs tuigreet directly on VT1. No X server is involved, so seat0
  # is already active by the time the session command runs.
  #
  # This replaces lightdm, which ran an X11 greeter and handed off from it
  # to a Wayland session. That handover is a race, and on 2026-09-11 it
  # started losing it: Hyprland opened the seat one to two seconds before
  # the greeter let go, logind still counted the greeter as the active
  # session, and aquamarine set libinput up against a seat whose devices it
  # was not yet allowed to open. Every keyboard was then lost for the life
  # of the session -- the pointer survived only because USB re-enumerated
  # it a moment later, which is what made it look like a dead keyboard
  # rather than a dead session. The tell in the log is
  #
  #   journalctl -t xsession -b -1 | grep 'Session is not active'
  #
  # which appears in exactly the boots that came up with no keyboard, and
  # in none of the ones that came up healthy.
  #
  # The i3 block below stays enabled on purpose, so "i3" remains selectable
  # at the login screen -- this is a hybrid-graphics laptop and the X11
  # session is the fallback if a Hyprland or NVIDIA update ever breaks the
  # Wayland one. Press F2 at the greeter to pick it.
  #
  # NB: services.greetd.vt no longer exists. The VT is fixed to 1, and the
  # module disables autovt@tty1 so getty does not fight for it.
  services.xserver.displayManager.lightdm.enable = false;

  services.greetd = {
    enable = true;
    # Keeps systemd's own boot output from being drawn over the TUI.
    useTextGreeter = true;
    settings.default_session.command = lib.concatStringsSep " " [
      "${pkgs.greetd.tuigreet}/bin/tuigreet"
      "--time"
      "--asterisks"
      "--remember" # pre-fill the last username
      "--remember-session" # and re-select the session it was used with
      "--sessions ${sessionDesktops}/share/wayland-sessions"
      "--xsessions ${sessionDesktops}/share/xsessions"
      # tuigreet's default wrapper is `startx /usr/bin/env`, and neither of
      # those paths exists here. X11 sessions need a wrapper at all because
      # greetd hands them a bare VT, whereas the NixOS xsession script only
      # launches the window manager and assumes a server is already up.
      "--xsession-wrapper '${pkgs.xinit}/bin/startx ${pkgs.coreutils}/bin/env'"
      # What runs before anything has been remembered, i.e. the first login
      # after this change. Same binary hyprland.desktop names; the three
      # variables below are the ones that .desktop file would have exported
      # and are set by hand here because --cmd bypasses it.
      "--cmd ${config.programs.hyprland.package}/bin/start-hyprland"
      "--env XDG_CURRENT_DESKTOP=Hyprland"
      "--env XDG_SESSION_DESKTOP=hyprland"
      "--env DESKTOP_SESSION=hyprland"
    ];
  };

  # Gives startx a NixOS-aware /etc/X11/xinit/xserverrc, so the X server the
  # i3 fallback brings up is the configured one with the configured
  # arguments. This is not a display manager and does not compete with
  # greetd; it exists only so --xsession-wrapper above has a working startx
  # to call.
  services.xserver.displayManager.startx.enable = true;

  services.xserver.desktopManager.xterm.enable = false;

  documentation.man.cache.enable = true;

  environment.pathsToLink = [ "/libexec" "/share/fish" ];
  services.xserver.windowManager.i3 = {
    enable = true;
    # NB: the i3-gaps fork is gone; gaps are upstream i3 since 4.22,
    # so this uses the default pkgs.i3 rather than naming a package.
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3lock
      i3blocks
    ];
    configFile = "/etc/i3.conf";
  };

  # Hyprland. The system module provides the session file, the polkit
  # rules and the xdg-desktop-portal wiring; the actual configuration is a
  # home-manager module in home/lontivero/hyprland.nix.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # xdg-desktop-portal-hyprland comes with programs.hyprland and handles
  # screencast/screenshot. The GTK portal is added for the file chooser,
  # which the Hyprland portal deliberately does not implement.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # hyprlock authenticates through PAM and needs its own service entry,
  # otherwise every unlock attempt fails regardless of the password.
  security.pam.services.hyprlock = { };

  # Enabled implicitly by other modules today, but stated explicitly
  # because the volume keys and the waybar audio module both drive
  # wireplumber directly -- this should not depend on an accident.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Thunar, the graphical file manager -- there was none before, only ranger,
  # which is a TUI and so cannot drag and drop at all.
  #
  # Chosen over Nautilus because it is GTK3 and therefore picks up the Nordic
  # theme from home/lontivero/gtk.nix; Nautilus is GTK4/libadwaita and largely
  # ignores GTK themes. It is also a native Wayland client, so dragging to and
  # from other Wayland clients (Firefox already is one) goes over
  # wl_data_device rather than being bridged through XWayland.
  #
  # NB: this module turns on programs.xfconf by itself -- Thunar keeps its
  # settings there, and without it nothing changed in the UI persists.
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin # "Extract Here" / "Create Archive" context menu
      thunar-volman # act on newly plugged-in drives and media
      thunar-media-tags-plugin # audio tags in properties and bulk rename
    ];
  };

  # Thunar needs all three of these and pulls in none of them itself:
  services.gvfs.enable = true; # Move to Trash, and sftp:// / smb:// mounts
  services.tumbler.enable = true; # thumbnails for images, video and PDFs
  services.udisks2.enable = true; # mounting removable drives, what thunar-volman drives

  # With no explicit default, inode/directory resolves to whichever installed
  # application claims it first. Today that is ranger, so "Open containing
  # folder" from Firefox opens a TUI; once Thunar claims it too the winner
  # would simply be undefined.
  #
  # This writes /etc/xdg/mimeapps.list, which sits BELOW ~/.config/mimeapps.list
  # in the XDG lookup order, so the user file is left alone -- it holds the
  # claude-cli scheme handler, and having home-manager take it over would turn
  # it into a read-only symlink into the store.
  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
  };

  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix {};

  # Do not suspend when close the laptop
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Configure keymap in X11
  services.xserver.xkb.layout = "latam,us";
  services.xserver.xkb.options = "eurosign:e, compose:menu, grp:alt_space_toggle";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  services.pulseaudio.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;
  users.users.lontivero = {
     isNormalUser = true;
     # hashedPassword = "$6$NDuMuWF2P3Z3aDSl$cai6jw.X8jvmaSHxRqbbzEtEVW7TApQYTex2dLprMlOvr0oYFBuCohg/HLoeH8r5b/K8Se2Kqo47pgTI6f6ND/";
     extraGroups = [ "wheel" "networkmanager" "libvirtd" "docker" ]; # Enable ‘sudo’ for the user.
   };

  # needed for vscode
  services.gnome.gnome-keyring.enable = true;
  home-manager = {
    useGlobalPkgs = true;
    # Install home-manager packages into /etc/profiles/per-user rather
    # than ~/.nix-profile, so they are part of the system generation.
    useUserPackages = true;
    # Rename pre-existing dotfiles instead of aborting the activation.
    backupFileExtension = "hm-bak";

    users.lontivero = import ./home/lontivero;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    curl
    wget
    firefox
    htop
    dmenu
    xclip
    bc
    qrencode
    ffmpeg
    mplayer
    rxvt-unicode-unwrapped
    alacritty

    git
    git-crypt
    git-absorb
    lazygit

    unzip
    feh
    tmux
    fzf
    jq
    ripgrep
    weechat
    rofi
    nitrogen
    ranger
    tree
    watch
    bat
    file
    killall
    patchelf
    direnv

    dunst
    viewnior
    mpd
    mpc
    acpi
    brightnessctl
    libnotify

    # Wayland equivalents of the X11 tools above. scrot, xclip and nitrogen
    # are kept because the i3 fallback session still uses them.
    scrot
    grim          # screenshots        (X11: scrot)
    slurp         # region selection   (X11: scrot -s)
    wl-clipboard  # wl-copy/wl-paste   (X11: xclip)
    wev           # key event debugger (X11: xev)
    pavucontrol
    papirus-icon-theme
    hyprpolkitagent

    lxappearance
    networkmanagerapplet

    mc
    sshfs
    graphviz
    pandoc
    gnuplot

    virt-manager
    spice spice-gtk
    spice-protocol
    virtio-win
    win-spice

    pinentry-tty

    signal-desktop
  ];

  # Solves problem for binaries that cannot find the interpreter
  system.activationScripts.ldso = lib.stringAfter [ "usrbinenv" ] ''                       
    mkdir -m 0755 -p /lib64                                                                
    ln -sfn ${pkgs.glibc.out}/lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2.tmp   
    mv -f /lib64/ld-linux-x86-64.so.2.tmp /lib64/ld-linux-x86-64.so.2 # atomically replace 
  '';

  environment.variables = {
    EDITOR = "nvim";
    TERMINAL = "alacritty";
    BROWSER = "firefox";
  };


  programs = {
      dconf = {
        enable = true;
      };
      fish = {
      	enable = true;
      };
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      powerline-fonts
      ubuntu-classic
      liberation_ttf
      nerd-fonts.fira-code
      nerd-fonts.monoid
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };
  services.pcscd.enable = true;
  
  nix = {
    package = pkgs.nixVersions.stable;
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      keep-outputs = true
      experimental-features = nix-command flakes
    '';
  };

  # List services that you want to enable:

  services.bitcoind.main = {
    enable = true;
    prune = 18000;
    group = "users";
    extraConfig = ''
      assumevalid = 00000000000000000000981da4d3caaea822ff0da785bd3b42d4bdf9051f8f3a
      blocksonly = 1
      blockfilterindex = 1
      peerblockfilters = 1
      disablewallet = 1
      fallbackfee=0.00001
      startupnotify = chmod g=r /var/lib/bitcoind-main/.cookie
      '';
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

