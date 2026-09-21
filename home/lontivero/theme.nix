# Nord palette, matching the Nordic GTK theme selected in gtk.nix, so the
# bar, launcher, notifications and window borders all agree with the
# widget theme instead of introducing a second colour scheme.
#
# This is a plain attrset, NOT a home-manager module -- it is not in the
# imports list. Consumers pull it in with:
#   let theme = import ./theme.nix; in ...
#
# Values are bare hex with no leading "#", because Hyprland wants
# rgba(RRGGBBAA) while CSS/rofi/dunst want #RRGGBB. Each consumer adds
# the prefix it needs.
{
  # Polar Night -- backgrounds, from darkest to lightest.
  base = "2e3440"; # nord0, bar and window background
  mantle = "3b4252"; # nord1, raised surfaces
  surface = "434c5e"; # nord2, inactive borders
  overlay = "4c566a"; # nord3, disabled text, separators

  # Snow Storm -- foregrounds.
  text = "d8dee9"; # nord4, primary text
  subtext = "e5e9f0"; # nord5
  bright = "eceff4"; # nord6

  # Frost -- accents.
  teal = "8fbcbb"; # nord7
  accent = "88c0d0"; # nord8, active borders, focused workspace
  steel = "81a1c1"; # nord9
  deep = "5e81ac"; # nord10

  # Aurora -- status colours.
  red = "bf616a"; # nord11, critical/urgent
  orange = "d08770"; # nord12, warning
  yellow = "ebcb8b"; # nord13, degraded
  green = "a3be8c"; # nord14, good
  purple = "b48ead"; # nord15

  font = "FiraCode Nerd Font";
  fontSize = 11;
}
