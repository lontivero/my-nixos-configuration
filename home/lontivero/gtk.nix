{ config, pkgs, ... }:
{
  gtk = {
    enable = true;

    # 26.05 is moving gtk4.theme off "whatever gtk.theme is" and onto null.
    # Still resolving to Nordic here, so this is a no-op today -- pinned so
    # GTK4 apps do not silently go unstyled when that default lands.
    gtk4.theme = config.gtk.theme;
    theme = {
        name = "Nordic";
        package = pkgs.nordic; # gnome3.gnome_themes_standard;
        # name = "Adwaita";
    };
  };
}
