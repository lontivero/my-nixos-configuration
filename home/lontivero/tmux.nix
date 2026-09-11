{ pkgs, ... }:
let
  theme = import ./theme.nix;
  c = name: "#${theme.${name}}";

  base = c "base";
  mantle = c "mantle";
  surface = c "surface";
  overlay = c "overlay";
  text = c "text";
  bright = c "bright";
  accent = c "accent";
  yellow = c "yellow";
  red = c "red";
in
{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    keyMode = "vi";

    # tmux-256color over screen-256color: it is the terminfo that actually
    # advertises italics and 256 colours, where screen-* predates both.
    # Present in nixpkgs' ncurses, checked with `infocmp tmux-256color`.
    terminal = "tmux-256color";

    # Windows and panes numbered from 1, because the keyboard is.
    baseIndex = 1;
    historyLimit = 50000;
    mouse = true;
    focusEvents = true;
    clock24 = true;

    # vim wants the Escape key to be Escape, not the start of a sequence.
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      #### Terminal capabilities ###########################################
      #
      # RGB rather than the older ",*:Tc" override -- terminal-features is
      # the supported spelling since tmux 3.2 and this is 3.6.
      set -as terminal-features ",*:RGB"
      set -g allow-passthrough on

      # Copying goes through OSC 52, so a yank inside tmux lands in the
      # Wayland clipboard via alacritty -- and keeps working over SSH and in
      # the i3/X11 fallback session, which a wl-copy pipe would not.
      set -g set-clipboard on

      #### Copy mode #######################################################
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      #### Windows and panes ###############################################
      setw -g pane-base-index 1

      # Close window 2 of 1,2,3 and the rest become 1,2 instead of 1,3.
      set -g renumber-windows on

      # New splits and windows inherit the current directory.
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Resize with prefix+HJKL, held down. Lowercase hjkl is left alone for
      # vim-tmux-navigator, which moves across vim splits and tmux panes.
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Be faster switching windows
      bind C-n next-window
      bind C-p previous-window

      bind -n Home send-key C-a
      bind -n End send-key C-e

      # Reload. NB: home-manager writes the config to ~/.config/tmux/tmux.conf
      # -- the old binding pointed at /etc/tmux.conf, which does not exist
      # here, so reloading silently did nothing.
      bind R run-shell ' \
        tmux source-file ~/.config/tmux/tmux.conf > /dev/null; \
        tmux display-message "config reloaded"'

      set -g display-time 2000

      #### Status bar ######################################################
      #
      # Nord, from theme.nix, replacing the catppuccin plugin -- everything
      # else on this desktop (waybar, rofi, dunst, GTK, borders) is Nord, and
      # since fish execs into tmux this bar is on screen permanently.
      set -g status-interval 5
      set -g status-justify left
      set -g status-style "bg=${mantle},fg=${text}"
      set -g status-left-length 40
      set -g status-right-length 60

      # The session block turns amber while the prefix is armed, which saves
      # a lot of "did that keypress register?".
      set -g status-left "#[fg=${base},bg=#{?client_prefix,${yellow},${accent}},bold]  #S #[fg=#{?client_prefix,${yellow},${accent}},bg=${mantle},nobold] "
      set -g status-right "#[fg=${overlay},bg=${mantle}]#[fg=${text},bg=${overlay}] %a %d %b #[fg=${accent},bg=${overlay}]#[fg=${base},bg=${accent},bold]  %H:%M "

      set -g window-status-format "#[fg=${overlay},bg=${mantle}] #I #[fg=${text}]#W#{?window_zoomed_flag, ,} "
      set -g window-status-current-format "#[fg=${mantle},bg=${overlay}]#[fg=${accent},bg=${overlay},bold] #I #W#{?window_zoomed_flag, ,} #[fg=${overlay},bg=${mantle},nobold]"
      set -g window-status-separator ""
      set -g window-status-bell-style "fg=${red},bg=${mantle},bold"

      set -g pane-border-style "fg=${surface}"
      set -g pane-active-border-style "fg=${accent}"
      set -g message-style "bg=${accent},fg=${base},bold"
      set -g mode-style "bg=${overlay},fg=${bright}"
      set -g clock-mode-colour "${accent}"
    '';
  };
}
