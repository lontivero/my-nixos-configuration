# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, lib, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.home-manager
      ./ssh.nix
      ./tmux.nix
      # ./picom.nix
      ./networking.nix
    ];

  nixpkgs.config.allowUnfree = true;

  # Manage the virtualisation services

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Plymouth boot splash screen
  boot.plymouth.enable = true;

  # For nvidia test
  # boot.kernelPackages = pkgs.linuxPackages_latest;

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
  
  hardware.opengl.enable = true;

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
  sound.enable = true;
  hardware.pulseaudio.enable = true;

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
  home-manager.users.lontivero = { pkgs, ... }: {
    home.stateVersion = "22.05";
    gtk = {
      enable = true;
      theme = {
          name = "Nordic";
          package = pkgs.nordic; # gnome3.gnome_themes_standard;
          # name = "Adwaita";
      };
    };
    programs = {
      man.generateCaches = true;
      #bat = {
      #  enable = true;
      #};
      fish = {
        enable = true;
        shellInit = ''
          set fish_color_autosuggestion brblack
          if status is-interactive
          and not set -q TMUX
            exec tmux
          end
        '';
        shellAliases = {
          gdiff = "git diff";
          gl = "git prettylog";
          gs = "git status";
          cat = "bat -p";
          grep = "rg";
          mkdir = "mkdir -p";
        };
        shellAbbrs = {
          n = "nvim";
        };
        functions = {
          mkdcd = {
            description = "Make a directory and enter it";
            body = "mkdir -p $argv[1]; and cd $argv[1]";
          };
          clip = {
            description = "xclip selection";
            body = "xclip -selection c $argv";
          };
          qr = {
            description = "Encode data as QR code";
            body = "qrencode -o - | feh -";
          };
        };
      };
      direnv = {
        enable = true;
      };
      git = {
        enable = true;
        package = pkgs.gitAndTools.gitFull;
        userName = "Lucas Ontivero";
        userEmail = "lucasontivero@gmail.com";
        aliases = {
          remotes = "remote -v";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          root = "rev-parse --show-toplevel";
          fixup = "!git log -n 10 --pretty=format:'%h %s' --no-merges | fzf | cut -d' ' -f1 | xargs -o git commit --fixup";
        };
        extraConfig = {
          # branch.autosetuprebase = "always";
          color.ui = true;
          core.askPass = ""; # needs to be empty to use terminal for ask pass
          credential.helper = "store"; # want to make this more secure
          github.user = "lontivero";
          init.defaultBranch = "master";
          rebase = {
            autosquash = true;
          };
          pull = {
            ff = "only";
          };
          sendemail = {
            smtpserver = "smtp.gmail.com";
            smtpuser = "lucasontivero";
            smtpencryption = "tls";
            smtpserverport = 587;
          };
        };
      };
      alacritty = {
        enable = true;

        settings = {
          env.TERM = "xterm-256color";
        };
      };
      i3status = {
        enable = true;

        general = {
          colors = true;
          color_good = "#8C9440";
          color_bad = "#A54242";
          color_degraded = "#DE935F";
        };

        modules = {
          ipv6.enable = false;
          "wireless _first_".enable = false;
          "battery all".enable = false;
        };
      };
      neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;

        plugins = with pkgs; [
          vimPlugins.vim-cue
          vimPlugins.vim-fugitive
          vimPlugins.which-key-nvim
          vimPlugins.nvim-whichkey-setup-lua

          vimPlugins.nvim-comment
          vimPlugins.vim-misc
          vimPlugins.telescope-nvim

          vimPlugins.nvim-treesitter
          vimPlugins.nvim-treesitter-textobjects

          # vimPlugins.coc-nvim
          vimPlugins.nvim-lspconfig
          vimPlugins.vim-fish
          vimPlugins.vim-airline
          vimPlugins.vim-airline-themes
          vimPlugins.vim-gitgutter

          vimPlugins.vim-markdown
          vimPlugins.vim-nix
          vimPlugins.vimwiki
        ];

        # extraConfig = (import ./vim-config.nix) { inherit sources; };
        extraConfig = pkgs.callPackage ./vim-config.nix {};      };
      vscode = {
        enable = true;
        extensions = with pkgs.vscode-extensions; [
          # Some example extensions...
          dracula-theme.theme-dracula
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];
      };
    };
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
    rxvt_unicode
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
    DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
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
      (nerdfonts.override { fonts = [ "FiraCode" "Monoid" ]; })
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
    package = pkgs.nixFlakes;
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
    prune = 8000;
    group = "users";
    extraConfig = ''
      assumevalid = 00000000000000000000981da4d3caaea822ff0da785bd3b42d4bdf9051f8f3a
      blocksonly = 1
      blockfilterindex = 1
      disablewallet = 1
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

