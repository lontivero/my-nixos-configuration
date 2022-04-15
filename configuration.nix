# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # For nvidia test
  boot.kernelPackages = pkgs.linuxPackages_latest;


  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # do not install what I dont want
  services.gnome.core-utilities.enable = false;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.defaultSession = "none+i3";
  services.xserver.desktopManager.xterm.enable = false;
  
  environment.pathsToLink = [ "/libexec" ];
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
       dmenu
       i3status
       i3lock
       i3blocks
    ];
  };

  # hardware.nvidia.modesetting.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];

  # Configure keymap in X11
  services.xserver.layout = "es,us";
  services.xserver.xkbOptions = "eurosign:e, compose:menu, grp:alt_space_toggle";

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
     extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };

  # needed for vscode
  services.gnome.gnome-keyring.enable = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.lontivero = { pkgs, ... }: {
    programs = {
      fish = {
        enable = true;
        shellAliases = {
          gdiff = "git diff";
          gl = "git prettylog";
          gs = "git status";
        };
      };
      git = {
        enable = true;
        userName = "Lucas Ontivero";
        userEmail = "lucasontivero@gmail.com";
        signing = {
          key = "key-fingerprint here";
          signByDefault = true;
        };
        aliases = {
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          root = "rev-parse --show-toplevel";
        };
        extraConfig = {
          # branch.autosetuprebase = "always";
          color.ui = true;
          core.askPass = ""; # needs to be empty to use terminal for ask pass
          credential.helper = "store"; # want to make this more secure
          github.user = "lontivero";
          init.defaultBranch = "master";
        };
      };
      alacritty = {
        enable = true;

        settings = {
          env.TERM = "xterm-256color";

          key_bindings = [
          ];
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
        # package = pkgs.neovim-nightly;

        plugins = with pkgs; [
          # customVim.vim-cue
          # customVim.vim-fish
          # customVim.vim-fugitive
          # customVim.vim-misc
          # customVim.pigeon
          # customVim.AfterColors

          # customVim.vim-nord
          # customVim.nvim-comment
          # customVim.nvim-lspconfig
          # customVim.nvim-plenary # required for telescope
          # customVim.nvim-telescope
          # customVim.nvim-treesitter
          # customVim.nvim-treesitter-playground
          # customVim.nvim-treesitter-textobjects

          # vimPlugins.vim-airline
          # vimPlugins.vim-airline-themes
          # vimPlugins.vim-gitgutter

          # vimPlugins.vim-markdown
          # vimPlugins.vim-nix
        ];

        # extraConfig = (import ./vim-config.nix) { inherit sources; };
      };
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
    ffmpeg
    mplayer
    rxvt_unicode
    alacritty
    git
    git-crypt
    unzip
    feh
    tmux
    fzf
    jq
    ripgrep
    rofi
    tree
    watch
    bat
    file
    killall
    patchelf
  ];

  environment.variables = {
    EDITOR = "nvim";
    TERMINAL = "alacritty";
  };


  programs = {
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      ubuntu_font_family
      liberation_ttf
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

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

