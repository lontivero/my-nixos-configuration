{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;

    # 26.05 flipped both of these to false by default. None of the plugins
    # below use the ruby or python3 remote-plugin hosts, so take the new
    # default -- stated explicitly so the option stops warning about it.
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs; [
      vimPlugins.vim-cue
      vimPlugins.vim-fugitive
      vimPlugins.which-key-nvim
      vimPlugins.nvim-whichkey-setup-lua

      vimPlugins.nvim-comment
      vimPlugins.vim-misc
      vimPlugins.telescope-nvim

      vimPlugins.nvim-treesitter
      vimPlugins.nvim-treesitter-textobjects

      # vimPlugins.coc-nvim
      vimPlugins.nvim-lspconfig
      vimPlugins.vim-fish
      vimPlugins.vim-airline
      vimPlugins.vim-airline-themes
      vimPlugins.vim-gitgutter

      vimPlugins.vim-markdown
      vimPlugins.vim-nix
    ];

    # extraConfig = (import ../../vim-config.nix) { inherit sources; };
    extraConfig = pkgs.callPackage ../../vim-config.nix {};
  };
}
