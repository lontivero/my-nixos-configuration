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
    ./starship.nix
    ./git.nix
    ./gtk.nix

    # Hyprland desktop. theme.nix is deliberately NOT in this list: it is a
    # plain attrset of colours that the modules below import directly.
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./dunst.nix
    ./lock.nix
    ./wallpaper.nix
    ./i3status.nix   # still used by the i3 fallback session
    ./neovim.nix
    ./ssh.nix
    ./tmux.nix
    # ./picom.nix
  ];

  home.stateVersion = "22.05";

  # Small enough not to deserve a file of their own.
  #
  # NB: programs.man.generateCaches is not set here, but still ends up
  # true: programs.fish turns it on with mkDefault so that `man <TAB>`
  # completion can use apropos. That means the man cache is built twice,
  # once here and once system-wide by documentation.man in
  # configuration.nix. Setting it to false below would stop the second
  # build at the cost of that fish completion.
  programs.direnv.enable = true;
}
