{ config, pkgs, ... }:
{
  home-manager.users.lontivero.services.picom = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeDelta = 5;
    opacityRule = [ 
      "100:name *= 'i3lock'"
      "99:fullscreen"
      "90:class_g = 'Alacritty' && focused"
      "65:class_g = 'Alacritty' && !focused"
    ];
      
    shadow = true;
    shadowOpacity = "0.75";
    extraOptions = ''
      xrender-sync-fence = true;
      mark-ovredir-focused = false;
      use-ewmh-active-win = true;
    '';
  };
}
