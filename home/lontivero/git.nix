{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    # 26.05 folded userName/userEmail/aliases/extraConfig into one freeform
    # `settings` attrset that maps straight onto git-config sections.
    settings = {
      user = {
        name = "Lucas Ontivero";
        email = "lucasontivero@gmail.com";
      };
      alias = {
        remotes = "remote -v";
        prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        root = "rev-parse --show-toplevel";
        fixup = "!git log -n 10 --pretty=format:'%h %s' --no-merges | fzf | cut -d' ' -f1 | xargs -o git commit --fixup";
      };

      # branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "lontivero";
      init.defaultBranch = "master";
      rebase = {
        autosquash = true;
      };
      pull = {
        ff = "only";
      };
      sendemail = {
        smtpserver = "smtp.gmail.com";
        smtpuser = "lucasontivero";
        smtpencryption = "tls";
        smtpserverport = 587;
      };
    };
  };
}
