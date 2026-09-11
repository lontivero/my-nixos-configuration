{ pkgs, ... }:
let
  theme = import ./theme.nix;
in
{
  # Replaces the i3 config's xss-lock + i3lock pair. hypridle holds the
  # logind sleep inhibitor and runs hyprlock before suspend, so the screen
  # is already locked by the time the machine goes down.
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 2; # brief window to abort an accidental lock
        no_fade_in = false;
      };

      background = [{
        # Blur whatever hyprpaper last set, so the lock screen follows the
        # rolling Bing wallpaper without needing its own copy of the image.
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
        brightness = 0.6;
      }];

      input-field = [{
        size = "300, 50";
        position = "0, -80";
        halign = "center";
        valign = "center";
        outline_thickness = 2;
        rounding = 8;
        dots_center = true;
        outer_color = "rgba(${theme.accent}ff)";
        inner_color = "rgba(${theme.base}dd)";
        font_color = "rgba(${theme.text}ff)";
        fail_color = "rgba(${theme.red}ff)";
        placeholder_text = "<i>password</i>";
        fail_text = "<i>wrong</i>";
      }];

      label = [
        {
          text = "$TIME";
          font_size = 96;
          font_family = theme.font;
          color = "rgba(${theme.bright}ff)";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:60000] date +'%A, %d %B'";
          font_size = 20;
          font_family = theme.font;
          color = "rgba(${theme.text}cc)";
          position = "0, 40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      };

      listener = [
        # Dim the backlight first as a warning, restore it on any input.
        {
          timeout = 300;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
        # NB: no suspend listener. configuration.nix sets
        # services.logind.lidSwitch = "ignore", i.e. this machine is
        # deliberately never put to sleep on its own; add one here if that
        # ever changes.
      ];
    };
  };
}
