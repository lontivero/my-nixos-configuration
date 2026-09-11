{ config, pkgs, ... }:
let
  theme = import ./theme.nix;
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    location = "center";

    # Set through extraConfig rather than the dedicated options because the
    # option names for modes have churned across home-manager releases;
    # these keys go into the .rasi verbatim and are stable.
    extraConfig = {
      modes = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      display-drun = "apps";
      display-run = "run";
      display-window = "window";
      sidebar-mode = true;
      kb-cancel = "Escape,super+d";
    };

    theme = {
      "*" = {
        background = mkLiteral "#${theme.base}";
        background-alt = mkLiteral "#${theme.mantle}";
        foreground = mkLiteral "#${theme.text}";
        selected = mkLiteral "#${theme.accent}";
        urgent = mkLiteral "#${theme.red}";
        font = "${theme.font} 12";
      };

      window = {
        transparency = "real";
        width = mkLiteral "36em";
        border-radius = mkLiteral "10px";
        background-color = mkLiteral "@background";
      };

      mainbox.children = map mkLiteral [ "inputbar" "listview" ];

      inputbar = {
        padding = mkLiteral "12px";
        spacing = mkLiteral "10px";
        background-color = mkLiteral "@background-alt";
        children = map mkLiteral [ "prompt" "entry" ];
      };

      prompt = {
        text-color = mkLiteral "@selected";
        background-color = mkLiteral "transparent";
      };

      entry = {
        placeholder = "search";
        placeholder-color = mkLiteral "#${theme.overlay}";
        background-color = mkLiteral "transparent";
      };

      listview = {
        lines = 10;
        columns = 1;
        scrollbar = false;
        padding = mkLiteral "8px";
      };

      element = {
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "10px";
        border-radius = mkLiteral "6px";
      };

      "element normal.normal".background-color = mkLiteral "transparent";
      "element selected.normal" = {
        background-color = mkLiteral "@selected";
        text-color = mkLiteral "#${theme.base}";
      };
      "element-icon" = {
        size = mkLiteral "1.2em";
        background-color = mkLiteral "transparent";
      };
      "element-text" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };
    };
  };
}
