# The login screen.
#
# greetd runs the greeter directly on VT1 and hands the chosen session a seat
# that is already active. That part is not new -- it replaced lightdm on
# 2026-09-11, after lightdm's X11 greeter kept still holding seat0 when
# Hyprland opened it, losing every keyboard for the life of the session. The
# tell in the log was
#
#   journalctl -t xsession -b -1 | grep 'Session is not active'
#
# and it appeared in exactly the boots that came up dead. Nothing below
# changes that: greetd still owns VT1, and the greeter is still the only
# thing between the boot splash and the session.
#
# What changed is the greeter itself. tuigreet drew a text UI straight onto
# the console, which worked but looked like a rescue shell. ReGreet is a
# GTK4 greeter for the same greetd, run inside cage -- a single-window
# wlroots compositor -- so the login screen is a Wayland client wearing the
# same Nordic theme and Nord palette as the rest of the desktop.
#
# If the greeter itself ever fails to come up, it is still recoverable --
# getty is untouched on tty2 through tty6 (greetd only claims tty1), and the
# previous generation is in the boot menu.
#
# The one new failure mode worth naming is the GPU. cage is wlroots, and
# this laptop has two cards -- the panel on the AMD one, HDMI hardwired to
# NVIDIA -- so an empty screen at boot would mean cage picked the wrong one.
# Left unset it chooses for itself, which is deliberate: pinning the GPU list
# by hand is exactly what killed the Hyprland session once already (see
# AQ_DRM_DEVICES in home/lontivero/hyprland.nix). If it ever does pick wrong,
# add WLR_DRM_DEVICES to the env prefix below, and use a /dev/dri/by-path/
# name rather than a cardN one, which is not stable across boots.
{ config, lib, pkgs, ... }:

let
  theme = import ./home/lontivero/theme.nix;

  # theme.nix stores bare hex. GTK CSS wants "#rrggbb" for opaque colours and
  # decimal components for the translucent ones, so both forms are derived
  # here rather than writing the palette out a second time.
  hex = name: "#${theme.${name}}";
  rgba = name: alpha:
    let
      value = theme.${name};
      component = offset: toString (lib.fromHexString (builtins.substring offset 2 value));
    in
    "rgba(${component 0}, ${component 2}, ${component 4}, ${alpha})";

  xkb = config.services.xserver.xkb;

  # Where the NixOS modules collect the .desktop file for every enabled
  # session. Only share/wayland-sessions has anything in it now that the i3
  # session is gone, but the loop below still walks both so adding an X11
  # session back is a one-line change in configuration.nix and nothing here.
  sessionDesktops = config.services.displayManager.sessionData.desktops;

  # ReGreet starts a session by running the Exec= line of its .desktop file
  # and nothing else: it does not read DesktopNames, and greetd itself
  # exports only XDG_SESSION_TYPE. A session launched that way comes up
  # without XDG_CURRENT_DESKTOP, which is the variable xdg-desktop-portal
  # reads to decide which backend to load -- without it the Hyprland portal
  # is never selected and screencast and the file chooser quietly fall back
  # to the wrong implementation.
  #
  # tuigreet had the same gap. The old config worked around it by passing
  # --cmd with three --env flags, which fixed the default session and left
  # every other entry in the list broken. This copies each session file with
  # its Exec pointed at a wrapper that exports the identity variables from
  # that file's own DesktopNames first, so every entry is correct.
  sessions = pkgs.runCommand "greeter-sessions"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      mkdir -p $out/libexec
      for dir in wayland-sessions xsessions; do
        [ -d ${sessionDesktops}/share/$dir ] || continue
        mkdir -p $out/share/$dir

        for desktop in ${sessionDesktops}/share/$dir/*.desktop; do
          name=$(basename "$desktop" .desktop)
          # DesktopNames is already colon-separated in XDG_CURRENT_DESKTOP
          # terms once the ';' separators are swapped; fall back to the file
          # name for session files that do not declare it.
          names=$(sed -n 's/^DesktopNames=//p' "$desktop" | head -1 | tr ';' ':' | sed 's/:$//')
          command=$(sed -n 's/^Exec=//p' "$desktop" | head -1)

          wrapper=$out/libexec/$name
          {
            echo "#!${pkgs.runtimeShell}"
            echo "export XDG_CURRENT_DESKTOP=''${names:-$name}"
            echo "export XDG_SESSION_DESKTOP=$name"
            echo "export DESKTOP_SESSION=$name"
            echo "exec $command \"\$@\""
          } > "$wrapper"
          chmod +x "$wrapper"

          sed "s|^Exec=.*|Exec=$wrapper|" "$desktop" > $out/share/$dir/$name.desktop
        done
      done
    '';
in
{
  programs.regreet = {
    enable = true;

    # Nordic is the same GTK theme the session uses (home/lontivero/gtk.nix),
    # so the login screen and the desktop behind it are one design rather
    # than two. Icons stay on Adwaita: Nordic ships no icon set, ReGreet only
    # draws a handful of symbolic icons, and symbolic icons are recoloured by
    # the GTK theme anyway -- a second icon theme would be closure weight for
    # three glyphs.
    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };

    # Same pointer as the session, declared in home/lontivero/cursor.nix.
    # This sets it for GTK; XCURSOR_* in the greetd command below sets it for
    # cage, which draws the pointer outside any window.
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    font = {
      name = theme.font;
      package = pkgs.nerd-fonts.fira-code;
      # A little above theme.fontSize, which is tuned for the bar. Nothing
      # else is competing for the screen here.
      size = 13;
    };

    settings = {
      GTK.application_prefer_dark_theme = true;

      appearance.greeting_msg = "Welcome back.";

      commands = {
        # NB: no x11_prefix. ReGreet only needs one for a session out of
        # share/xsessions, which greetd hands a bare VT -- the NixOS xsession
        # script assumes a server is already running, so such a session has to
        # be wrapped in startx. There are no X11 sessions left to wrap. Adding
        # one back means restoring both this and
        # services.xserver.displayManager.startx.enable, which is what gives
        # startx a NixOS-aware xserverrc.
        reboot = [ "${pkgs.systemd}/bin/systemctl" "reboot" ];
        poweroff = [ "${pkgs.systemd}/bin/systemctl" "poweroff" ];
      };

      widget.clock = {
        format = "%A %d %B   %H:%M";
        timezone = config.time.timeZone;
        # Pango would otherwise resize the frame on every minute whose text
        # is a different width, and the frame is centred, so it would twitch.
        label_width = 420;
      };
    };

    # The Nordic theme dresses the widgets; this dresses the greeter itself --
    # the backdrop, which is a bare GtkWindow, and the three floating frames
    # ReGreet overlays on it, which are plain frames with no styling of their
    # own. The login card is deliberately translucent so the gradient reads
    # through it.
    extraCss = ''
      window {
        background-color: ${hex "base"};
        background-image:
          radial-gradient(circle at 18% 12%, ${rgba "deep" "0.45"} 0%, ${rgba "base" "0"} 55%),
          radial-gradient(circle at 84% 82%, ${rgba "accent" "0.28"} 0%, ${rgba "base" "0"} 52%),
          linear-gradient(160deg, ${hex "base"} 0%, ${hex "mantle"} 58%, ${hex "surface"} 100%);
      }

      frame.background {
        background-color: ${rgba "base" "0.82"};
        border: 1px solid ${rgba "overlay" "0.9"};
        border-radius: 16px;
        box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
        padding: 8px;
      }

      /* The only other frame is the one wrapping the error bar, which stays
         empty until a login fails -- left unstyled it would draw a small
         empty box above the buttons for the whole session. */
      frame:not(.background) {
        background: transparent;
        border: none;
      }

      /* The clock is the only label that is a direct child of a styled frame --
         the login card holds a grid, and the error bar an infobar. */
      frame.background > label {
        color: ${hex "subtext"};
        font-size: 150%;
        padding: 10px 24px;
      }

      label {
        color: ${hex "text"};
      }

      entry, passwordentry {
        background-color: ${hex "mantle"};
        background-image: none;
        color: ${hex "bright"};
        caret-color: ${hex "accent"};
        border: 1px solid ${hex "surface"};
        border-radius: 8px;
        padding: 8px 10px;
      }

      entry:focus-within, passwordentry:focus-within {
        border-color: ${hex "accent"};
        box-shadow: 0 0 0 2px ${rgba "accent" "0.25"};
      }

      button {
        background-color: ${hex "surface"};
        background-image: none;
        color: ${hex "subtext"};
        border: 1px solid ${hex "overlay"};
        border-radius: 8px;
        padding: 6px 16px;
      }

      button:hover {
        background-color: ${hex "overlay"};
      }

      /* Login. */
      button.suggested-action {
        background-color: ${hex "accent"};
        color: ${hex "base"};
        border-color: ${hex "accent"};
        font-weight: bold;
      }

      button.suggested-action:hover {
        background-color: ${hex "teal"};
      }

      /* Reboot and Power Off, which sit on the backdrop rather than in a
         frame -- outlined instead of filled so they stay secondary. */
      button.destructive-action {
        background-color: transparent;
        color: ${hex "red"};
        border-color: ${rgba "red" "0.55"};
      }

      button.destructive-action:hover {
        background-color: ${rgba "red" "0.18"};
        color: ${hex "bright"};
      }

      infobar, infobar.error > revealer > box {
        background-color: ${rgba "red" "0.9"};
        color: ${hex "bright"};
        border-radius: 10px;
      }
    '';
  };

  services.greetd = {
    enable = true;

    # NB: services.greetd.vt no longer exists. The VT is fixed to 1, and the
    # module disables autovt@tty1 so getty does not fight for it.
    #
    # The stock ReGreet command is assembled by the NixOS module; it is
    # restated here because the greeter needs an environment the module does
    # not set. greetd starts the greeter with a nearly empty environment, so
    # each of these has to be named explicitly:
    #
    #   XDG_DATA_DIRS  where ReGreet looks for sessions (it appends
    #                  /xsessions and /wayland-sessions to every entry) and
    #                  where GTK looks for the Nordic theme and the icons.
    #                  The wrapped session files come first so they win over
    #                  the unwrapped originals that Hyprland also installs
    #                  into the system profile.
    #   XCURSOR_*      cage draws the pointer itself, outside any window, and
    #                  reads these rather than the GTK settings.
    #   XKB_DEFAULT_*  the keyboard layout the password is typed on. On a
    #                  latam layout this is not cosmetic.
    settings.default_session.command = lib.concatStringsSep " " (
      [
        "${pkgs.coreutils}/bin/env"
        # Force cage to use only the AMD iGPU, which drives the internal panel.
        # Without this, cage sees both GPUs and may split the greeter across
        # monitors or pick the NVIDIA card which has no panel attached at boot.
        "WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:05:00.0-card"
        "XDG_DATA_DIRS=${sessions}/share:/run/current-system/sw/share"
        "XCURSOR_THEME=${config.programs.regreet.cursorTheme.name}"
        "XCURSOR_SIZE=24"
        "XKB_DEFAULT_LAYOUT=${xkb.layout}"
      ]
      ++ lib.optional (xkb.variant != "") "XKB_DEFAULT_VARIANT=${xkb.variant}"
      ++ lib.optional (xkb.options != "")
        "XKB_DEFAULT_OPTIONS=${lib.replaceStrings [ " " ] [ "" ] xkb.options}"
      ++ [
        # GTK4 talks to AccountsService over the session bus to list users,
        # and there is no session bus on a bare VT.
        "${pkgs.dbus}/bin/dbus-run-session"
        (lib.getExe pkgs.cage)
        (lib.escapeShellArgs config.programs.regreet.cageArgs)
        "--"
        (lib.getExe config.programs.regreet.package)
      ]
    );
  };
}
