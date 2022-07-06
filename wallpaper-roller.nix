{ pkgs, ... }:
pkgs.writeShellScriptBin "wallpaper-roller.sh" ''
    TIMEOUT=3600

    while [ true ]; do
      if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        url="http://www.bing.com"$(curl -s "http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=50" | jq -r '.images[].url' | shuf -n1)
        name=$(basename "$url")
        cd ~/.background-images && wget -q "$url"
        ${pkgs.nitrogen}/bin/nitrogen --set-scaled --save "$name"
        TIMEOUT=3600
      else
        TIMEOUT=300
      fi
      sleep $TIMEOUT
    done
  ''
