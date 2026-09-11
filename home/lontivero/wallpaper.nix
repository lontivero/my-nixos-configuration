{ pkgs, ... }:
let
  # Port of wallpaper-roller.nix to Wayland. Same behaviour as the i3
  # version -- pull a random Bing image of the day into ~/.background-images
  # once an hour, back off to 5 minutes while offline -- but it hands the
  # image to hyprpaper over hyprctl instead of shelling out to nitrogen,
  # which is X11-only.
  roller = pkgs.writeShellScriptBin "wallpaper-roller" ''
    set -u
    dir="$HOME/.background-images"
    mkdir -p "$dir"

    while true; do
      if ${pkgs.iputils}/bin/ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        url="http://www.bing.com"$(${pkgs.curl}/bin/curl -s \
          "http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=50" \
          | ${pkgs.jq}/bin/jq -r '.images[].url' | ${pkgs.coreutils}/bin/shuf -n1)
        name=$(${pkgs.coreutils}/bin/basename "$url")
        name="''${name%%&*}"

        if [ ! -f "$dir/$name" ]; then
          ${pkgs.wget}/bin/wget -q -O "$dir/$name" "$url" || true
        fi

        if [ -s "$dir/$name" ]; then
          # unload all, then preload+apply, or hyprpaper leaks every image
          # it has ever been handed into RAM over a long session.
          ${pkgs.hyprland}/bin/hyprctl hyprpaper unload all >/dev/null 2>&1 || true
          ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$dir/$name" >/dev/null 2>&1 || true
          ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$dir/$name" >/dev/null 2>&1 || true
        fi
        sleep 3600
      else
        sleep 300
      fi
    done
  '';
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true; # required: the roller drives it over hyprctl
      splash = false;
      preload = [ ];
      wallpaper = [ ];
    };
  };

  systemd.user.services.wallpaper-roller = {
    Unit = {
      Description = "Rotate the desktop wallpaper from Bing's image archive";
      After = [ "hyprpaper.service" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${roller}/bin/wallpaper-roller";
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
