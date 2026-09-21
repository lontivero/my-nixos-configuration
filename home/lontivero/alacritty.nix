{ ... }:
let
  theme = import ./theme.nix;

  # theme.nix stores bare hex for Hyprland's sake; alacritty wants "#rrggbb".
  c = name: "#${theme.${name}}";
in
{
  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      window = {
        # Alacritty pads by { x = 0, y = 0 } out of the box, so the first
        # column sits flush against the frame and glyphs that overhang their
        # cell -- the top-left ones worst of all -- get clipped by it.
        #
        # 8px also matches decoration:rounding in hyprland.nix, so the text
        # clears the rounded corner rather than running under the curve.
        # Note this is a per-side value and is scaled by DPI.
        padding = {
          x = 8;
          y = 8;
        };

        # A window is almost never an exact multiple of the cell size. By
        # default the remainder is all dumped on the right/bottom edge, which
        # reads as lopsided padding; this spreads it evenly instead.
        dynamic_padding = true;

        # Hyprland draws the border and handles the corners, so client-side
        # decorations would only add a second frame inside the first.
        decorations = "None";

        # Slight transparency, picked up by decoration.blur in hyprland.nix.
        # NB: alacritty's own `blur` option only works on macOS and KDE, so
        # the compositor has to be the one doing it. Set this to 1.0 if the
        # background ever makes text hard to read.
        opacity = 0.92;
      };

      # Nord, matching theme.nix -- so the terminal, the bar, the launcher
      # and the GTK widgets are finally all the same scheme.
      colors = {
        primary = {
          background = c "base";
          foreground = c "text";
        };
        cursor = {
          text = c "base";
          cursor = c "text";
        };
        selection = {
          text = "CellForeground";
          background = c "overlay";
        };
        # Nord maps the 16 ANSI slots onto Polar Night + Aurora + Frost.
        # normal and bright differ only in black, cyan and white.
        normal = {
          black = c "mantle";
          red = c "red";
          green = c "green";
          yellow = c "yellow";
          blue = c "steel";
          magenta = c "purple";
          cyan = c "accent";
          white = c "subtext";
        };
        bright = {
          black = c "overlay"; # what fish_color_autosuggestion resolves to
          red = c "red";
          green = c "green";
          yellow = c "yellow";
          blue = c "steel";
          magenta = c "purple";
          cyan = c "teal";
          white = c "bright";
        };
      };

      font = {
        # The Nerd Font build is what carries the powerline and git glyphs
        # the starship prompt and the tmux status bar are drawn with.
        normal = {
          family = theme.font;
          style = "Regular";
        };
        bold = {
          family = theme.font;
          style = "Bold";
        };
        italic = {
          family = theme.font;
          style = "Italic";
        };
        bold_italic = {
          family = theme.font;
          style = "Bold Italic";
        };
        size = theme.fontSize;
      };

      cursor.style = {
        shape = "Block";
        blinking = "On";
      };

      # The default 10k fills up fast with long build logs.
      scrolling.history = 50000;

      # Mouse-selected text goes straight to the clipboard, not just to the
      # middle-click primary selection.
      selection.save_to_clipboard = true;
    };
  };
}
