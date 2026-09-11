{ config, pkgs, ... }:
let
  theme = import ./theme.nix;
  inherit (config.lib.formats.rasi) mkLiteral;

  # rasi understands #RRGGBBAA, so the launcher can be translucent and let
  # the Hyprland blur (layerrule in hyprland.nix) do the rest. Without the
  # layerrule this just looks like flat transparency.
  alpha = colour: opacity: mkLiteral "#${theme.${colour}}${opacity}";
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

      # The prompt is rendered as a pill by the theme below, so these strings
      # are what sits inside it. The leading glyphs are Nerd Font: grid,
      # terminal, window.
      display-drun = "  apps";
      display-run = "  run";
      display-window = "  windows";

      # The tab strip along the bottom. Worth having now that it is styled --
      # previously sidebar-mode was on but mainbox.children left it out, so
      # it was enabled and invisible.
      sidebar-mode = true;

      # fzf-style matching: "fif" finds "Firefox". levenshtein sorting puts
      # the closest match on top rather than the first one alphabetically.
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";

      # Papirus comes from environment.systemPackages; rofi picks icon themes
      # up out of the XDG data dirs, which /run/current-system/sw is one of.
      icon-theme = "Papirus-Dark";

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
        text-color = mkLiteral "@foreground";
      };

      window = {
        transparency = "real";
        width = mkLiteral "44em";
        border = mkLiteral "2px";
        border-color = alpha "accent" "cc";
        border-radius = mkLiteral "16px";
        background-color = alpha "base" "e6";
        # The padding lives on mainbox so the border hugs the rounded corner.
        padding = mkLiteral "0";
      };

      mainbox = {
        padding = mkLiteral "18px";
        spacing = mkLiteral "14px";
        background-color = mkLiteral "transparent";
        children = map mkLiteral [ "inputbar" "listview" "mode-switcher" ];
      };

      # A single rounded search field, with the mode name as a coloured pill
      # inside it instead of a bare word floating at the left margin.
      inputbar = {
        padding = mkLiteral "10px 14px";
        spacing = mkLiteral "12px";
        border-radius = mkLiteral "12px";
        background-color = alpha "mantle" "cc";
        children = map mkLiteral [ "prompt" "entry" ];
      };

      prompt = {
        padding = mkLiteral "4px 10px";
        border-radius = mkLiteral "8px";
        background-color = mkLiteral "@selected";
        text-color = mkLiteral "#${theme.base}";
        vertical-align = mkLiteral "0.5";
      };

      entry = {
        placeholder = "type to search";
        placeholder-color = mkLiteral "#${theme.overlay}";
        background-color = mkLiteral "transparent";
        vertical-align = mkLiteral "0.5";
      };

      # fixed-height keeps the window the same size as results are filtered
      # away, so the launcher stops jumping around under the pointer as you
      # type. cycle = false stops the selection wrapping past the ends.
      listview = {
        lines = 8;
        columns = 1;
        spacing = mkLiteral "4px";
        scrollbar = false;
        fixed-height = true;
        cycle = false;
        background-color = mkLiteral "transparent";
      };

      element = {
        padding = mkLiteral "10px 14px";
        spacing = mkLiteral "14px";
        border-radius = mkLiteral "10px";
        background-color = mkLiteral "transparent";
      };

      "element normal.normal".text-color = mkLiteral "@foreground";
      "element alternate.normal".background-color = mkLiteral "transparent";
      "element normal.urgent".text-color = mkLiteral "@urgent";

      "element selected.normal" = {
        background-color = mkLiteral "@selected";
        text-color = mkLiteral "#${theme.base}";
      };
      "element selected.urgent" = {
        background-color = mkLiteral "@urgent";
        text-color = mkLiteral "#${theme.base}";
      };

      "element-icon" = {
        size = mkLiteral "1.8em";
        background-color = mkLiteral "transparent";
        vertical-align = mkLiteral "0.5";
      };
      "element-text" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };

      # The mode tabs: unobtrusive until one is current.
      mode-switcher = {
        spacing = mkLiteral "8px";
        background-color = mkLiteral "transparent";
      };

      button = {
        padding = mkLiteral "6px";
        border-radius = mkLiteral "8px";
        background-color = alpha "mantle" "cc";
        text-color = mkLiteral "#${theme.overlay}";
      };

      "button selected" = {
        background-color = mkLiteral "@selected";
        text-color = mkLiteral "#${theme.base}";
      };
    };
  };
}
