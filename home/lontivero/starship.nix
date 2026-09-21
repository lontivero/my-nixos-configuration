# Starship prompt, themed from the same Nord palette as the rest of the
# desktop. Replaces fish's stock prompt.
#
# Shape (two lines, so a long path never squeezes the input):
#
#     ~/.nixos   hyprland !2 ?1   ❄ impure        12:04
#   ❯
#
# home-manager wires this into fish automatically via
# programs.starship.enableFishIntegration, which defaults to true.
{ lib, ... }:
let
  theme = import ./theme.nix;

  # theme.nix stores bare hex so Hyprland can say rgba(RRGGBBAA); starship
  # wants the CSS spelling, so every colour picks up a "#" here.
  c = name: "#${theme.${name}}";

  bright = c "bright";
  teal = c "teal";
  accent = c "accent";
  steel = c "steel";
  red = c "red";
  orange = c "orange";
  yellow = c "yellow";
  green = c "green";
  purple = c "purple";
  overlay = c "overlay";

  # The two block backgrounds. Kept as names because the powerline joins
  # below have to agree about them in three separate places.
  dirBg = c "deep"; # nord10, the directory block
  gitBg = c "overlay"; # nord3, the git block
in
{
  programs.starship = {
    enable = true;

    settings = {
      # A blank line between prompts. With a two-line prompt this is what
      # keeps successive commands from running together visually.
      add_newline = true;

      # NB: `\${custom.nogit}` is escaped for Nix, not for starship -- the
      # generated TOML gets a literal ${custom.nogit}. Bare `$custom` would
      # mean "every custom module", and starship would then read `.nogit` as
      # literal text and print it.
      format = lib.concatStrings [
        "$hostname"
        "[](fg:${dirBg})"
        "$directory"
        "\${custom.nogit}"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$nix_shell"
        "$status"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      right_format = "$time";

      # Only shows up over SSH, where knowing which box you are on matters.
      hostname = {
        ssh_only = true;
        format = "[$hostname ](fg:${orange} bold)";
      };

      directory = {
        # truncate_to_repo defaults to true, so inside a repo this shows the
        # path relative to the repo root rather than the whole home path.
        format = "[  $path](bg:${dirBg} fg:${bright} bold)[$read_only](bg:${dirBg} fg:${yellow})[ ](bg:${dirBg})";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " ";
        home_symbol = "~";
      };

      # The powerline join from the directory block into the git block lives
      # here rather than in `format`, because this module renders nothing at
      # all outside a repo -- which is exactly when the join must not appear.
      git_branch = {
        format = "[](fg:${dirBg} bg:${gitBg})[  $branch](bg:${gitBg} fg:${teal} bold)";
        symbol = "";
      };

      # REBASING 3/7, MERGING, CHERRY-PICKING, BISECTING...
      git_state = {
        format = "[ ($state $progress_current/$progress_total)](bg:${gitBg} fg:${orange} bold)";
      };

      # One colour per kind of dirtiness, so the shape of the mess is
      # readable at a glance instead of being one undifferentiated blob.
      #
      # The closing cap is here for the same reason the opening join is in
      # git_branch: git_status still renders its literal text in a *clean*
      # repo (the count variables just come out empty) but renders nothing
      # at all outside one. It is the only module that can close the bar.
      git_status = {
        format = lib.concatStrings [
          "[$conflicted](bg:${gitBg} fg:${red} bold)"
          "[$staged](bg:${gitBg} fg:${green})"
          "[$modified](bg:${gitBg} fg:${yellow})"
          "[$renamed](bg:${gitBg} fg:${purple})"
          "[$deleted](bg:${gitBg} fg:${red})"
          "[$untracked](bg:${gitBg} fg:${steel})"
          "[$stashed](bg:${gitBg} fg:${purple})"
          "[$ahead_behind](bg:${gitBg} fg:${accent})"
          "[ ](bg:${gitBg})"
          "[](fg:${gitBg})"
        ];
        conflicted = " =";
        staged = " +$count";
        modified = " !$count";
        renamed = " »$count";
        deleted = " ✘$count";
        untracked = " ?$count";
        stashed = " *$count";
        ahead = " ⇡$count";
        behind = " ⇣$count";
        diverged = " ⇕⇡$ahead_count⇣$behind_count";
      };

      # Closes the directory block when git_status is not there to do it.
      # `when` shows the module on exit 0, so the bang inverts it -- hence a
      # real shell rather than the default bare exec.
      custom.nogit = {
        description = "Closing cap for the directory block outside a git repo";
        when = "! git rev-parse --is-inside-work-tree";
        command = "";
        format = "[](fg:${dirBg})";
        shell = [ "bash" "--noprofile" "--norc" ];
      };

      # Worth having given how much of this repo is `nix develop` / nix-shell.
      nix_shell = {
        format = "[ ❄ $name]($style)";
        style = "fg:${steel} bold";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      status = {
        disabled = false;
        format = "[ ✘ $status]($style)";
        style = "fg:${red} bold";
      };

      cmd_duration = {
        format = "[ ⏱ $duration]($style)";
        style = "fg:${overlay}";
        min_time = 2000; # only for commands that actually took a while
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "fg:${overlay}";
        time_format = "%H:%M";
      };

      character = {
        success_symbol = "[❯](bold fg:${green})";
        error_symbol = "[❯](bold fg:${red})";
        vicmd_symbol = "[❮](bold fg:${yellow})";
      };
    };
  };
}
