# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, lib, pkgs, ... }:
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

  # Hyprland is the default session. The i3 block below stays enabled on
  # purpose, so "none+i3" remains selectable at the login screen -- this is
  # a hybrid-graphics laptop and the X11 session is the fallback if a
  # Hyprland or NVIDIA update ever breaks the Wayland session.
  services.displayManager.defaultSession = "hyprland";
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

