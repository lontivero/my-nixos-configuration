{ config, pkgs, ... }:
let
  theme = import ./theme.nix;

  terminal = "${pkgs.alacritty}/bin/alacritty";
  browser = "${pkgs.firefox}/bin/firefox";
  # The rofi configured in rofi.nix, so the launcher that opens is the
  # themed one. pkgs.rofi is Wayland-capable since rofi-wayland was merged
  # back into it.
  rofi = "${config.programs.rofi.finalPackage}/bin/rofi";
  grimshot = "${pkgs.grim}/bin/grim";
  slurp = "${pkgs.slurp}/bin/slurp";
  wlcopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # The default follows stateVersion, which is still 21.11 here, so this is
    # already what we get -- pinned so the config format cannot quietly switch
    # to Lua under us. The generated ~/.config/hypr/hyprland.conf is hyprlang.
    configType = "hyprlang";

    # programs.hyprland in configuration.nix installs the compositor and
    # its portal system-wide. Setting these to null stops home-manager
    # pulling in a second copy; it then manages only the config file.
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";

      #### Displays #########################################################
      #
      # eDP-1 hangs off the AMD iGPU and runs at 120Hz; HDMI-A-1 hangs off
      # the NVIDIA dGPU and runs at 60Hz. Under X11 both were stacked at
      # +0+0 (mirrored) and the whole Screen was driven at one rate, which
      # threw away the 120Hz panel. Wayland drives each output at its own
      # refresh rate, so the external is placed to the right instead.
      monitor = [
        "eDP-1,1920x1080@120.21,0x0,1"
        "HDMI-A-1,1920x1080@60,1920x0,1"
        ",preferred,auto,1" # anything else plugged in later
      ];

      #### Environment ######################################################
      env = [
        # NOTE: AQ_DRM_DEVICES was pinned here, iGPU first:
        #
        #   AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:05:00.0-card:/dev/dri/by-path/pci-0000:01:00.0-card
        #     AMD Cezanne (drives eDP-1) ..^      NVIDIA GA107M (drives HDMI-A-1) ..^
        #
        # That list was the one thing this setup did differently from a stock
        # one, and the session died in CBackend::create() -- precisely where
        # aquamarine resolves it against the devices udev enumerated. Left
        # unset, aquamarine picks the GPUs itself, which is the path everyone
        # else runs. Re-pin it only if a GPU is actually chosen wrong, and
        # read the log first to decide which order to ask for.
        "LIBVA_DRIVER_NAME,radeonsi" # video decode on the iGPU, not NVIDIA
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1" # Electron/Chromium apps run native Wayland
      ];

      #### Logging #########################################################
      #
      # Hyprland says almost nothing by default -- the first attempt at this
      # session left behind a backtrace and no reason. With these two on it
      # narrates startup to stdout, and lightdm's session wrapper pipes that
      # through `systemd-cat -t xsession`, so the whole thing lands in the
      # journal and survives the reboot. Read it back with:
      #
      #   journalctl -t xsession -b -1      # the boot before this one
      #   journalctl -t xsession -S -10m    # the last ten minutes
      #
      # Noisy. Turn both off once the session is healthy.
      debug = {
        disable_logs = false;
        enable_stdout_logs = true;
        # Idle at low refresh -- meaningful on battery. This used to be
        # misc:vfr; it lives under debug now. Not to be confused with
        # misc:vrr, which still exists and means adaptive sync instead.
        vfr = true;
      };

      #### Look and feel ####################################################
      #
      # NB: the i3 config used `gaps inner 32`, i.e. 32px BETWEEN windows.
      # Hyprland's gaps_in is per-window-edge, so gaps_in = 16 reproduces
      # that exactly. Both numbers live here if you want to tune them.
      general = {
        gaps_in = 16;
        gaps_out = 16;
        border_size = 2;
        "col.active_border" = "rgba(${theme.accent}ff)";
        "col.inactive_border" = "rgba(${theme.surface}ff)";
        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 12;
          render_power = 2;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
        ];
        animation = [
          "windows,1,4,easeOutQuint,popin 87%"
          "border,1,6,easeOutQuint"
          "fade,1,4,easeOutQuint"
          "workspaces,1,4,easeInOutCubic,slide"
        ];
      };

      # NB: there is no dwindle:pseudotile any more -- Hyprland dropped the
      # global toggle. Pseudotiling is per window now: the `pseudo` dispatcher
      # ($mod+s below) and the `pseudo = true` window rule.
      dwindle = {
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      #### Input ############################################################
      #
      # Mirrors services.xserver.xkb.* from configuration.nix, which only
      # applies to the X11 session. Hyprland needs its own copy.
      input = {
        kb_layout = "latam,us";
        kb_options = "eurosign:e,compose:menu,grp:alt_space_toggle";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      # gestures:workspace_swipe is gone; gestures are declared one per line
      # now, as `<fingers>, <direction>, [mod], <action>`. The gestures:*
      # tree still holds the tuning knobs (workspace_swipe_distance & co).
      gesture = [
        "3, horizontal, workspace"
      ];

      #### Startup ##########################################################
      #
      # waybar, dunst, hypridle and hyprpaper are NOT here: they are systemd
      # user services bound to hyprland-session.target by their own modules,
      # so they restart cleanly and survive a Hyprland reload.
      exec-once = [
        "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
      ];

      #### Window rules #####################################################
      # Ported from the i3 `assign` block, with class names refreshed.
      # Hyprland 0.53 rewrote this syntax wholesale; the old form is rejected
      # outright, which is what produced the wall of "Config error" toasts.
      #
      # The grammar is comma-separated `<name> <value>` pairs, where the
      # SEPARATOR IS A SPACE, not an "=". handleWindowrule splits each element
      # at its first space and takes everything after it as the value, so
      # `match:class = ^(foo)$` parses happily and then matches nothing at all,
      # because the regex it stores is literally "= ^(foo)$". That failure is
      # silent -- hyprctl reports "ok" and no config error is raised.
      #
      # Effects are snake_case (noblur -> no_blur) and take an explicit value,
      # so a boolean rule is `float true`, never a bare `float`. Matchers are
      # spelled `match:<prop>`; class/title are still regexes, so the anchors
      # carry over from the old config unchanged.
      windowrule = [
        "workspace 1, match:class ^([Aa]lacritty)$"
        "workspace 2, match:class ^(firefox|chromium-browser|Chromium)$"
        "workspace 3, match:class ^([Tt]hunar|org.gnome.Nautilus)$"
        "workspace 4, match:class ^([Cc]ode|jetbrains-rider|[Rr]ider)$"
        "workspace 5, match:class ^(vlc|mpv|[Mm]player)$"
        "workspace 6, match:class ^([Ss]ignal|[Ss]ignal-desktop)$"
        "workspace 7, match:class ^([Gg]imp|[Ii]nkscape|libreoffice.*|org.pwmt.zathura)$"
        "workspace 8, match:class ^([Tt]ransmission.*)$"
        "workspace 9, match:class ^([Ll]xappearance|[Pp]avucontrol|virt-manager)$"

        # Float the small utility windows rather than tiling them.
        "float true, match:class ^([Pp]avucontrol|[Ll]xappearance|nm-connection-editor)$"
        "float true, match:title ^(Picture-in-Picture)$"
        "pin true, match:title ^(Picture-in-Picture)$"

        # Dim and blur everything behind a fullscreen window.
        "no_blur true, match:class ^(firefox)$"
      ];

      # The scratchpad terminal, replacing the i3 `dropdown` instance.
      # Hyprland's special workspace is a better fit than i3's scratchpad:
      # it toggles as an overlay instead of cycling a hidden window list.
      workspace = [
        "special:dropdown,on-created-empty:${terminal} --class dropdown"
      ];

      #### Keybindings ######################################################
      #
      # Deliberately kept close to the old i3 map, including the unusual
      # j/k/l/semicolon direction keys.
      bind = [
        # Launching
        "$mod,Return,exec,${terminal}"
        "$mod,d,exec,${rofi} -show drun" # the i3 config had this commented out
        "$mod,p,exec,${rofi} -show run"
        "$mod,Tab,exec,${rofi} -show window"
        "$mod SHIFT,f,exec,${browser}"
        "$mod SHIFT,q,killactive,"

        # Focus -- i3's j/k/l/semicolon, plus arrows
        "$mod,j,movefocus,l"
        "$mod,k,movefocus,d"
        "$mod,l,movefocus,u"
        "$mod,semicolon,movefocus,r"
        "$mod,left,movefocus,l"
        "$mod,down,movefocus,d"
        "$mod,up,movefocus,u"
        "$mod,right,movefocus,r"

        # Move windows
        "$mod SHIFT,j,movewindow,l"
        "$mod SHIFT,k,movewindow,d"
        "$mod SHIFT,l,movewindow,u"
        "$mod SHIFT,semicolon,movewindow,r"
        "$mod SHIFT,left,movewindow,l"
        "$mod SHIFT,down,movewindow,d"
        "$mod SHIFT,up,movewindow,u"
        "$mod SHIFT,right,movewindow,r"

        # Layout. i3's `split h` / `split v` become dwindle preselection:
        # the NEXT window opens in the chosen direction.
        "$mod,h,layoutmsg,preselect r"
        "$mod,v,layoutmsg,preselect d"
        # NB: togglesplit is a dwindle layout message, not a dispatcher --
        # as a bare dispatcher it fails with "Invalid dispatcher: togglesplit".
        "$mod,e,layoutmsg,togglesplit" # i3: layout toggle split
        "$mod,w,togglegroup," # i3: layout tabbed -- groups are the analogue
        "$mod,f,fullscreen,0"
        "$mod SHIFT,space,togglefloating,"
        "$mod,s,pseudo," # i3 had `layout stacking`; no analogue, pseudotile instead

        # Scratchpad
        "$mod SHIFT,Return,togglespecialworkspace,dropdown"

        # Screenshots -- grim/slurp replace scrot, wl-copy replaces xclip
        "$mod,Print,exec,${grimshot} -g \"$(${slurp})\" - | ${wlcopy} -t image/png"
        "$mod SHIFT,Print,exec,${grimshot} -g \"$(${slurp})\" \"$HOME/Screenshots/$(date +%Y-%m-%d_%H:%M:%S).png\""

        # Session
        "$mod SHIFT,c,exec,hyprctl reload"
        "$mod SHIFT,e,exit,"
      ]
      ++ (
        # Workspaces 1-10. NB: the old i3 config bound $mod+0 to an
        # undefined $ws10 variable (it had defined $ws0), so the 10th
        # workspace never worked. Fixed here.
        builtins.concatLists (builtins.genList
          (i:
            let ws = toString (i + 1);
                key = toString (if i == 9 then 0 else i + 1);
            in [
              "$mod,${key},workspace,${ws}"
              "$mod SHIFT,${key},movetoworkspace,${ws}"
            ])
          10)
      );

      # Repeat-on-hold bindings for the hardware keys.
      bindel = [
        ",XF86AudioRaiseVolume,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"
        ",XF86AudioLowerVolume,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86MonBrightnessUp,exec,${brightnessctl} set 5%+"
        ",XF86MonBrightnessDown,exec,${brightnessctl} set 5%-"
      ];

      bindl = [
        ",XF86AudioMute,exec,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute,exec,${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      # Mouse -- i3's floating_modifier
      bindm = [
        "$mod,mouse:272,movewindow"
        "$mod,mouse:273,resizewindow"
      ];
    };

    # Submaps have to be ordered, which an attrset cannot express, so the
    # two modes from the i3 config live here as literal config text.
    extraConfig = ''
      # ---- resize mode (i3: $mod+r) ------------------------------------
      bind = $mod, r, submap, resize
      submap = resize
        binde = , j, resizeactive, -40 0
        binde = , k, resizeactive, 0 40
        binde = , l, resizeactive, 0 -40
        binde = , semicolon, resizeactive, 40 0
        binde = , left, resizeactive, -40 0
        binde = , down, resizeactive, 0 40
        binde = , up, resizeactive, 0 -40
        binde = , right, resizeactive, 40 0
        bind = , Return, submap, reset
        bind = , Escape, submap, reset
        bind = $mod, r, submap, reset
      submap = reset

      # ---- system mode (i3: $mod+Pause) --------------------------------
      bind = $mod, Pause, submap, system
      submap = system
        bind = , l, exec, loginctl lock-session
        bind = , l, submap, reset
        bind = , e, exit,
        bind = , s, exec, systemctl suspend
        bind = , s, submap, reset
        bind = , h, exec, systemctl hibernate
        bind = , h, submap, reset
        bind = , r, exec, systemctl reboot
        bind = SHIFT, s, exec, systemctl poweroff
        bind = , Return, submap, reset
        bind = , Escape, submap, reset
      submap = reset
    '';
  };
}
