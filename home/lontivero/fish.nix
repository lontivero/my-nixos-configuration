{ ... }:
let
  # theme.nix stores bare hex, which is exactly the spelling fish's colour
  # variables want -- no "#" prefix here, unlike alacritty or starship.
  theme = import ./theme.nix;
in
{
  programs.fish = {
    enable = true;

    shellInit = ''
      if status is-interactive
      and not set -q TMUX
        exec tmux
      end
    '';

    # Syntax highlighting for the command line itself, in the same Nord
    # palette as the starship prompt above it and the tmux bar below it.
    # These only matter interactively, so they live here rather than in
    # shellInit, which also runs for scripts.
    interactiveShellInit = ''
      set -g fish_greeting ""

      set -g fish_color_normal ${theme.text}
      set -g fish_color_command ${theme.accent}
      set -g fish_color_keyword ${theme.steel}
      set -g fish_color_quote ${theme.green}
      set -g fish_color_redirection ${theme.teal}
      set -g fish_color_end ${theme.purple}
      set -g fish_color_error ${theme.red}
      set -g fish_color_param ${theme.text}
      set -g fish_color_option ${theme.steel}
      set -g fish_color_comment ${theme.overlay}
      set -g fish_color_operator ${theme.teal}
      set -g fish_color_escape ${theme.teal}
      set -g fish_color_autosuggestion ${theme.overlay}
      set -g fish_color_valid_path --underline
      set -g fish_color_selection --background=${theme.surface}
      set -g fish_color_search_match --background=${theme.surface}

      set -g fish_pager_color_prefix ${theme.accent} --bold
      set -g fish_pager_color_completion ${theme.text}
      set -g fish_pager_color_description ${theme.overlay}
      set -g fish_pager_color_progress ${theme.overlay}
      set -g fish_pager_color_selected_background --background=${theme.surface}
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
        description = "Copy to the system clipboard";
        # Was xclip, which does nothing under Hyprland, and then a branch on
        # WAYLAND_DISPLAY while the i3 session still existed. The desktop is
        # Wayland-only now, so there is one tool again.
        body = "wl-copy $argv";
      };
      qr = {
        description = "Encode data as QR code";
        body = "qrencode -o - | feh -";
      };
    };
  };
}
