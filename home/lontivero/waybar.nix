{ pkgs, ... }:
let
  theme = import ./theme.nix;
in
{
  programs.waybar = {
    enable = true;

    # Run as a systemd user service bound to hyprland-session.target rather
    # than an exec-once, so it comes back on its own if it ever dies and
    # can be restarted with `systemctl --user restart waybar`.
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 0;

      modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [
        "network"
        "cpu"
        "temperature"
        "memory"
        "disk"
        "backlight"
        "wireplumber"
        "battery"
        "tray"
      ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        sort-by-number = true;
      };

      # Shows "resize" / "system" when one of the submaps is active, which
      # is the Hyprland equivalent of i3's mode indicator.
      "hyprland/submap".format = "󰌌 {}";

      "hyprland/window" = {
        format = "{title}";
        max-length = 60;
        separate-outputs = true;
      };

      clock = {
        format = "󰃰 {:%a %d %b  %H:%M}";
        format-alt = "󰃰 {:%Y-%m-%d %H:%M:%S}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          on-scroll = 1;
          format = {
            months = "<span color='#${theme.bright}'><b>{}</b></span>";
            today = "<span color='#${theme.accent}'><b>{}</b></span>";
          };
        };
      };

      # interval = 1 is what makes the up/down rate meaningful; the module
      # computes throughput as a delta between polls.
      network = {
        interval = 1;
        format-wifi = "󰖩 {essid} 󰇚 {bandwidthDownBytes} 󰕒 {bandwidthUpBytes}";
        format-ethernet = "󰈀 {ipaddr} 󰇚 {bandwidthDownBytes} 󰕒 {bandwidthUpBytes}";
        format-linked = "󰈀 {ifname} (no IP)";
        format-disconnected = "󰖪 offline";
        tooltip-format = "{ifname} · {ipaddr}/{cidr} · via {gwaddr}\n󰇚 {bandwidthDownBytes}  󰕒 {bandwidthUpBytes}";
        on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
      };

      cpu = {
        interval = 2;
        format = "󰻠 {usage}%";
        tooltip = true;
        on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.htop}/bin/htop --sort-key PERCENT_CPU";
      };

      # hwmon numbering is not stable across boots, so this points at the
      # k10temp sensor by its PCI device path instead of /sys/class/hwmon/hwmonN.
      temperature = {
        hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
        input-filename = "temp1_input"; # Tctl
        interval = 2;
        critical-threshold = 85;
        format = "󰔏 {temperatureC}°C";
        format-critical = "󰸁 {temperatureC}°C";
      };

      memory = {
        interval = 5;
        format = "󰍛 {percentage}%";
        tooltip-format = "{used:0.1f}G used of {total:0.1f}G  ·  swap {swapUsed:0.1f}G/{swapTotal:0.1f}G";
        on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.htop}/bin/htop --sort-key PERCENT_MEM";
      };

      # One ext4 root filesystem on this machine, so a single module covers
      # it. Add another `disk#name` entry with its own path for more mounts.
      disk = {
        interval = 60;
        path = "/";
        format = "󰋊 {free}";
        tooltip-format = "{used} used of {total} ({percentage_used}%)  ·  {free} free on {path}";
      };

      backlight = {
        format = "󰃟 {percent}%";
        on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
        on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      };

      wireplumber = {
        format = "󰕾 {volume}%";
        format-muted = "󰝟 muted";
        on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      battery = {
        bat = "BAT1"; # this machine's battery; ACAD is the adapter
        interval = 10;
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
        tooltip-format = "{timeTo}  ·  {power:0.1f}W";
      };

      tray = {
        icon-size = 16;
        spacing = 10;
      };
    };

    style = ''
      /* Nord, sourced from theme.nix so the bar matches the Nordic GTK theme. */
      * {
        font-family: "${theme.font}", sans-serif;
        font-size: ${toString theme.fontSize}pt;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: rgba(46, 52, 64, 0.92);
        color: #${theme.text};
      }

      /* Every right-hand module gets the same breathing room. */
      #network, #cpu, #temperature, #memory, #disk,
      #backlight, #wireplumber, #battery, #tray, #clock {
        padding: 0 12px;
      }

      #clock {
        color: #${theme.bright};
        font-weight: bold;
      }

      #workspaces button {
        padding: 0 10px;
        color: #${theme.overlay};
        background: transparent;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: #${theme.accent};
        border-bottom: 2px solid #${theme.accent};
      }

      #workspaces button.urgent {
        color: #${theme.red};
        border-bottom: 2px solid #${theme.red};
      }

      #workspaces button:hover {
        background: #${theme.mantle};
        color: #${theme.bright};
      }

      #submap {
        padding: 0 12px;
        color: #${theme.base};
        background: #${theme.yellow};
        font-weight: bold;
      }

      #window {
        padding: 0 12px;
        color: #${theme.subtext};
      }

      #network        { color: #${theme.steel}; }
      #cpu            { color: #${theme.teal}; }
      #temperature    { color: #${theme.green}; }
      #memory         { color: #${theme.purple}; }
      #disk           { color: #${theme.deep}; }
      #backlight      { color: #${theme.yellow}; }
      #wireplumber    { color: #${theme.accent}; }
      #battery        { color: #${theme.green}; }

      #network.disconnected,
      #temperature.critical,
      #wireplumber.muted {
        color: #${theme.red};
      }

      #battery.warning  { color: #${theme.orange}; }

      /* Blink only when it is genuinely urgent. */
      #battery.critical:not(.charging) {
        color: #${theme.bright};
        background: #${theme.red};
        animation: blink 1s steps(2, start) infinite;
      }

      @keyframes blink {
        to { background: transparent; color: #${theme.red}; }
      }
    '';
  };
}
