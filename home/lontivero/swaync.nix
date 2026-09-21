{ ... }:
let
  theme = import ./theme.nix;
in
{
  # SwayNotificationCenter replaces dunst.
  #
  # dunst pops a notification up and then forgets it: `dunstctl history` can
  # redisplay one, but there is no panel, no unread count and no way to click
  # a notification from five minutes ago and have the sending application act
  # on it. swaync is a notification daemon AND a control centre -- it keeps
  # every notification in a scrollable panel, groups them by application, and
  # a click still invokes the notification's default action, which is what
  # makes "open the thing this told me about" work after the toast is gone.
  #
  # It speaks the same org.freedesktop.Notifications interface, so nothing
  # that sends notifications (lowbattery-alert, notify-send, Firefox) changes.
  #
  # NB: swaync is Wayland-only -- it draws on wlr-layer-shell. The systemd
  # unit the home-manager module generates carries
  # ConditionEnvironment=WAYLAND_DISPLAY and is bound to
  # hyprland-session.target, which is the only session there is.
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";

      # Toasts float above everything; the panel sits on the top layer so a
      # fullscreen window still covers it.
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;

      # Our style.css has to beat swaync's built-in stylesheet, which is
      # loaded at application priority.
      cssPriority = "user";

      # The panel. No offset for the bar is needed the way dunst needed one:
      # control-center-exclusive-zone (default true) means the surface asks
      # for a zone of 0, which makes the compositor lay it out inside the
      # usable area -- i.e. below waybar -- without reserving any space of
      # its own, so opening the panel does not reflow the tiled windows.
      control-center-margin-top = 8;
      control-center-margin-right = 8;
      control-center-margin-bottom = 8;
      control-center-margin-left = 0;
      control-center-width = 460;
      control-center-height = 700;
      fit-to-screen = false;

      notification-window-width = 420;

      # Same timeouts dunst had, including "a critical notification never
      # goes away on its own" -- the low-battery alert depends on that.
      timeout-low = 5;
      timeout = 10;
      timeout-critical = 0;

      # Which application sent a notification is shown two ways: every row
      # carries the sending application's icon (image-visibility = always
      # keeps that column there even when the notification has no image of
      # its own), and notifications from the same application collapse into
      # one group whose header spells the application's name out.
      notification-grouping = true;
      notification-icon-size = 48;
      image-visibility = "always";
      notification-body-image-height = 120;
      notification-body-image-width = 240;

      # "3 min ago" rather than a wall-clock time, which is the more useful
      # form in a list you only look at after the fact.
      relative-timestamps = true;

      notification-2fa-action = true;
      notification-inline-replies = true;
      keyboard-shortcuts = true;
      hide-on-clear = true;
      hide-on-action = true;
      transition-time = 150;
      text-empty = "Nothing new";

      # Dropped from the default set: "inhibitors", which is only ever
      # non-empty if something has taken a notification inhibitor lock.
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd.text = "Do not disturb";
        notifications.vexpand = true;
      };
    };

    # Nord, sourced from theme.nix, so the panel matches the bar and the
    # launcher. swaync 0.12 is GTK4 and drives its whole stylesheet from
    # custom properties on :root, so overriding those recolours every widget
    # without having to restate its rules.
    style = ''
      :root {
        /* The two translucent surfaces are spelled out as rgba() because
           theme.nix stores bare hex and these need an alpha channel. Both
           are theme.base, the same colour and opacity as window#waybar. */
        --cc-bg: rgba(46, 52, 64, 0.94);
        --noti-bg: 59, 66, 82; /* theme.mantle, as the r,g,b triple swaync composes with --noti-bg-alpha */
        --noti-bg-alpha: 0.96;

        --noti-bg-opaque: #${theme.mantle};
        --noti-bg-darker: #${theme.base};
        --noti-bg-hover: #${theme.surface};
        --noti-bg-hover-opaque: #${theme.surface};
        --noti-bg-focus: #${theme.surface};
        --noti-border-color: #${theme.surface};
        --noti-close-bg: #${theme.overlay};
        --noti-close-bg-hover: #${theme.red};

        --text-color: #${theme.text};
        --text-color-disabled: #${theme.overlay};
        --bg-selected: #${theme.accent};

        --border-radius: 8px;
        --notification-icon-size: 48px;
        --notification-group-icon-size: 24px;
        --font-size-summary: 13px;
        --font-size-body: 12px;
      }

      /* Fallback for the @define-color names swaync still honours. */
      @define-color cc-bg rgba(46, 52, 64, 0.94);
      @define-color noti-bg rgba(59, 66, 82, 0.96);
      @define-color noti-bg-opaque #${theme.mantle};
      @define-color noti-bg-darker #${theme.base};
      @define-color noti-bg-hover #${theme.surface};
      @define-color noti-bg-hover-opaque #${theme.surface};
      @define-color noti-bg-focus #${theme.surface};
      @define-color noti-border-color #${theme.surface};
      @define-color noti-close-bg #${theme.overlay};
      @define-color noti-close-bg-hover #${theme.red};
      @define-color text-color #${theme.text};
      @define-color text-color-disabled #${theme.overlay};
      @define-color bg-selected #${theme.accent};

      * {
        font-family: "${theme.font}", sans-serif;
      }

      .control-center {
        border: 1px solid #${theme.surface};
      }

      /* Panel header: "Notifications" and the Clear all button. */
      .widget-title {
        color: #${theme.bright};
        margin: 8px 8px 4px 8px;
        font-size: 1.2rem;
        font-weight: bold;
      }

      .widget-title > button {
        color: #${theme.text};
        background: #${theme.mantle};
        border: 1px solid #${theme.surface};
        border-radius: 6px;
        padding: 2px 10px;
        font-size: 0.9rem;
        font-weight: normal;
      }

      .widget-title > button:hover {
        background: #${theme.surface};
        color: #${theme.bright};
      }

      .widget-dnd {
        color: #${theme.subtext};
        margin: 4px 8px 8px 8px;
        font-size: 1rem;
      }

      .widget-dnd > switch:checked {
        background: #${theme.accent};
      }

      /* The per-application header a group grows once it holds more than one
         notification -- icon on the left, application name next to it. */
      .notification-group .notification-group-headers .notification-group-header {
        color: #${theme.accent};
        font-size: 0.95rem;
        font-weight: bold;
      }

      .notification-row .notification-background .notification
      .notification-default-action .notification-content .text-box .summary {
        color: #${theme.bright};
        font-weight: bold;
      }

      .notification-row .notification-background .notification
      .notification-default-action .notification-content .text-box .time {
        color: #${theme.overlay};
      }

      .notification-row .notification-background .notification
      .notification-default-action .notification-content .text-box .body {
        color: #${theme.text};
      }

      /* Left border in the urgency colour, the one piece of dunst's look
         worth keeping: red for critical, accent for normal, muted for low. */
      .notification-row .notification-background .notification {
        border-left: 3px solid #${theme.accent};
      }

      .notification-row .notification-background .notification.low {
        border-left-color: #${theme.overlay};
      }

      .notification-row .notification-background .notification.critical {
        border-left-color: #${theme.red};
      }

      /* Buttons an application attaches to a notification ("Reply",
         "Open"...), as opposed to the default action on the body itself. */
      .notification-row .notification-background .notification
      .notification-action > button {
        color: #${theme.text};
        background: #${theme.mantle};
        border-top: 1px solid #${theme.surface};
      }

      .notification-row .notification-background .notification
      .notification-action > button:hover {
        background: #${theme.surface};
        color: #${theme.bright};
      }

      .control-center .control-center-list-placeholder {
        color: #${theme.overlay};
      }
    '';
  };
}
