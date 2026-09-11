{ ... }:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_color_autosuggestion brblack
      if status is-interactive
      and not set -q TMUX
        exec tmux
      end
    '';
    shellAliases = {
      gdiff = "git diff";
      gl = "git prettylog";
      gs = "git status";
      cat = "bat -p";
      grep = "rg";
      mkdir = "mkdir -p";
    };
    shellAbbrs = {
      n = "nvim";
    };
    functions = {
      mkdcd = {
        description = "Make a directory and enter it";
        body = "mkdir -p $argv[1]; and cd $argv[1]";
      };
      clip = {
        description = "xclip selection";
        body = "xclip -selection c $argv";
      };
      qr = {
        description = "Encode data as QR code";
        body = "qrencode -o - | feh -";
      };
    };
  };
}
