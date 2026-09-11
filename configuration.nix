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

  # Enable the GNOME Desktop Environment.
  services.displayManager.defaultSession = "none+i3";
  services.xserver.desktopManager.xterm.enable = false;

  documentation.man.generateCaches = true;

  environment.pathsToLink = [ "/libexec" "/share/fish" ];
  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3lock
      i3blocks
    ];
    configFile = "/etc/i3.conf";
  };

  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix {};

  # Do not suspend when close the laptop
  services.logind.lidSwitch = "ignore";

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
  home-manager.useGlobalPkgs = true;
  home-manager.users.lontivero = import ./home/lontivero;

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
    mpc_cli
    acpi
    brightnessctl
    scrot
    libnotify

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
    win-virtio
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
      ubuntu_font_family
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

