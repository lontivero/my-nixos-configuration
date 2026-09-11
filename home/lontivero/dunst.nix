{ pkgs, ... }:
let
  theme = import ./theme.nix;
in
{
  # dunst was already the notifier under i3 and works natively on Wayland,
  # so this keeps it rather than swapping in mako -- one less thing to
  # relearn. It runs as a systemd user service via the home-manager module.
  services.dunst = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = "(300, 450)";
        height = 300;
        origin = "top-right";
        offset = "(16, 44)"; # clears the 34px bar plus a margin
        scale = 0;
        gap_size = 8;

        frame_width = 2;
        corner_radius = 8;
        separator_color = "frame";

        font = "${theme.font} 11";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        word_wrap = true;

        icon_position = "left";
        max_icon_size = 48;

        mouse_left_click = "do_action, close_current";
        mouse_middle_click = "close_all";
        mouse_right_click = "close_current";
      };

      urgency_low = {
        background = "#${theme.base}";
        foreground = "#${theme.overlay}";
        frame_color = "#${theme.surface}";
        timeout = 5;
      };

      urgency_normal = {
        background = "#${theme.base}";
        foreground = "#${theme.text}";
        frame_color = "#${theme.accent}";
        timeout = 10;
      };

      # Never auto-dismiss a critical notification -- this is what the
      # low-battery alert uses.
      urgency_critical = {
        background = "#${theme.base}";
        foreground = "#${theme.bright}";
        frame_color = "#${theme.red}";
        timeout = 0;
      };
    };
  };
}
