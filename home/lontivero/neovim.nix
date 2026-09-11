{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;

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
      vimPlugins.vimwiki
    ];

    # extraConfig = (import ../../vim-config.nix) { inherit sources; };
    extraConfig = pkgs.callPackage ../../vim-config.nix {};
  };
}
