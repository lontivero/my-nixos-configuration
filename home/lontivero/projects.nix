# The per-project development sessions: a rofi menu that opens a project and
# one that switches between the projects already open.
#
# NOT a home-manager module -- like theme.nix, this is a plain function that
# returns an attrset, here of two packages. It is imported twice: hyprland.nix
# needs the store paths to bind $mod+o and $mod+i to them, and default.nix puts
# both on PATH so they can also be driven by hand from a terminal. `import` is
# memoised, so both callers get the same two derivations.
#
# The design, and why a workspace per project, is written up at the top of
# scripts/project-menu.sh.
{ pkgs, config }:
let
  # The devshell entry point. Kept as its own package rather than inlined into
  # project-menu because it is genuinely useful on its own -- `project-devshell
  # Nostra` from any terminal is the same shell the menu opens.
  #
  # runtimeInputs is deliberately thin: `nix` and `nix-shell` come from the
  # system profile instead (see the note in the script), and there is nothing
  # else to provide.
  devshell = pkgs.writeShellApplication {
    name = "project-devshell";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./scripts/project-devshell.sh;
  };
in
{
  inherit devshell;

  menu = pkgs.writeShellApplication {
    name = "project-menu";
    runtimeInputs = [
      devshell # resolved with `command -v`, so it has to be here
      pkgs.coreutils # basename, comm
      pkgs.jq # reading hyprctl -j
      pkgs.alacritty # the project terminal
      pkgs.libnotify # notify-send, so a cold start says something
      # The themed rofi from rofi.nix, exactly as hyprland.nix does it, so the
      # picker looks like the launcher rather than like stock rofi.
      config.programs.rofi.finalPackage
      # hyprctl is not here on purpose: it ships with the compositor, which
      # configuration.nix installs system-wide and home-manager is told not to
      # duplicate (package = null in hyprland.nix). Adding pkgs.hyprland for
      # one binary would pull in that second copy.
    ];
    text = builtins.readFile ./scripts/project-menu.sh;
  };
}
