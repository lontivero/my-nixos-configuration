{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
        name = "Nordic";
        package = pkgs.nordic; # gnome3.gnome_themes_standard;
        # name = "Adwaita";
    };
  };
}
