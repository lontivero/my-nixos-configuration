# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, outputs, lib, pkgs, ... }:

{
  # Shared system configuration. Hardware, hostname and anything else
  # specific to a single machine lives in hosts/<name>/ instead.
  imports =
    [ inputs.home-manager.nixosModules.home-manager
      ./networking.nix
      ./greeter.nix
      ./gossip.nix
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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # do not install what I dont want
  # services.gnome.core-utilities.enable = false;

  documentation.man.cache.enable = true;

  environment.pathsToLink = [ "/libexec" "/share/fish" ];
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

  # Do not suspend when close the laptop
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Keyboard layout. Nothing reads this as an X11 setting any more -- the X
  # server is off -- but services.xserver.xkb is still the one place the
  # layout is written down: greeter.nix turns it into XKB_DEFAULT_* for the
  # login screen, and home/lontivero/hyprland.nix mirrors it into input:kb_*.
  services.xserver.xkb.layout = "latam,us";
  services.xserver.xkb.options = "eurosign:e, compose:menu, grp:alt_space_toggle";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  services.pulseaudio.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;
  users.users.lontivero = {
     isNormalUser = true;
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
    ranger
    tree
    watch
    bat
    file
    killall
    patchelf
    direnv

    viewnior
    mpd
    mpc
    acpi
    brightnessctl
    libnotify

    # The desktop is Wayland-only. scrot, xclip and nitrogen used to sit
    # alongside these for the i3 session and went with it.
    grim          # screenshots
    slurp         # region selection
    wl-clipboard  # wl-copy/wl-paste
    wev           # key event debugger
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
    spotify
    # gossip is in ./gossip.nix, which patches it
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

