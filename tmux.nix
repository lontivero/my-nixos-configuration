{ config, pkgs, home-manager, ... }:
{
  home-manager.users.lontivero.programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    shortcut = "a";
    keyMode = "vi";
    extraConfig = ''
      setw -g mouse on
      
      # Stay in same directory when split
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      bind-key R run-shell ' \
      tmux source-file /etc/tmux.conf > /dev/null; \
      tmux display-message "sourced /etc/tmux.conf"'

      # Be faster switching windows
      bind C-n next-window
      bind C-p previous-window

      # Force true colors
      set-option -ga terminal-overrides ",*:Tc"

      set-option -g mouse on
      set-option -g focus-events on

      bind -n Home send-key C-a
      bind -n End send-key C-e

      set-option -g repeat-time 100
      set -sg escape-time 0
    '';
  };
}


