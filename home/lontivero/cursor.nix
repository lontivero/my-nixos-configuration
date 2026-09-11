{ pkgs, ... }:
{
  # There was no cursor theme configured at all, so every toolkit fell back to
  # whatever it found first -- in practice the ancient X11 "cursor" font, which
  # is where the black three-dimensional blob and the sideways-arrow-with-a-tail
  # came from, and which changes shape depending on whether the window under the
  # pointer is a Wayland client, an XWayland client or the compositor itself.
  #
  # Bibata-Modern-Classic is a plain arrow in all three cases. Bibata-Modern-Ice
  # is the same shape in white if the black one ever disappears into a dark
  # window; the package ships both, so switching is a one-word edit here.
  #
  # home.pointerCursor is the single place to say this: it installs the theme,
  # links it into ~/.local/share/icons and ~/.icons, sets XCURSOR_THEME and
  # XCURSOR_SIZE, writes the Xresources for the i3 fallback session, and hands
  # gtk.cursorTheme the same values so GTK apps agree with the compositor.
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;

    gtk.enable = true;
    x11.enable = true;
    # Symlinks into ~/.icons as well. Some XWayland clients still look only
    # there, Firefox among them.
    dotIcons.enable = true;

    # NB: deliberately NOT hyprcursor.enable. That only sets HYPRCURSOR_THEME,
    # and Bibata is an XCursor theme with no hyprcursor variant packaged in
    # nixpkgs -- pointing Hyprland at a hyprcursor theme that does not exist
    # makes it log a miss on every cursor change before falling back to the
    # XCursor one it would have used anyway.
  };
}
