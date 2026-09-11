# home-manager configuration for lontivero.
#
# These are plain home-manager modules: they set `programs.*` / `gtk.*`
# directly, and configuration.nix wires the whole directory in with
# `home-manager.users.lontivero = import ./home/lontivero;`.
{ ... }:
{
  imports = [
    ./alacritty.nix
    ./fish.nix
    ./git.nix
    ./gtk.nix
    ./i3status.nix
    ./neovim.nix
    ./ssh.nix
    ./tmux.nix
    # ./picom.nix
  ];

  home.stateVersion = "22.05";

  # Small enough not to deserve a file of their own.
  programs.man.generateCaches = true;
  programs.direnv.enable = true;
}
