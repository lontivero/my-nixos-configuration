{ pkgs } :       
let
  wiki2html = pkgs.callPackage ./wiki2html.nix {};
in
''
  set nocompatible " use vim defaults

  set backspace=indent,eol,start " Allow backspacing over everything in insert mode
  let mapleader=","
  command! W :w " Seriously, guys. It's not like :W is bound to anything anyway.

  map <C-5> :noh<CR>

  " Use system clipboard
  set clipboard+=unnamedplus

  " Window movement without the extra ctrl+w press only ctrl+(h,j,k,l)
  nmap <C-h> <C-w>h
  nmap <C-j> <C-w>j
  nmap <C-k> <C-w>k
  nmap <C-l> <C-w>l

  " Shortcut to rapidly toggle `set list`
  nmap <leader>l :set list!<CR>

  " Shortcut to map ; to :
  nnoremap ; :
  set nostartofline   " don't jump to first character when paging
  set sm              " show matching braces

  " Searching
  set hlsearch
  set incsearch
  set ignorecase
  set smartcase
  set wildignorecase


  set nocompatible    " use vim defaults
  set number          " show line numbers
  set numberwidth=4   " line numbering takes up to 4 spaces
  set ruler           " show the cursor position all the time
  
  " Set encoding
  set encoding=utf-8
  
  " Whitespace stuff
  set tabstop=4
  set shiftwidth=4
  set softtabstop=4
  set expandtab
  
  " Show invisibles
  "set list
  
  " Searching
  set hlsearch
  set incsearch
  set ignorecase
  set smartcase
  set wildignorecase

  " air-line
  let g:airline_powerline_fonts = 1

  if !exists('g:airline_symbols')
      let g:airline_symbols = {}
  endif

  " unicode symbols
  let g:airline_left_sep = '»'
  let g:airline_left_sep = '▶'
  let g:airline_right_sep = '«'
  let g:airline_right_sep = '◀'
  let g:airline_symbols.linenr = '␊'
  let g:airline_symbols.linenr = '␤'
  let g:airline_symbols.linenr = '¶'
  let g:airline_symbols.branch = '⎇'
  let g:airline_symbols.paste = 'ρ'
  let g:airline_symbols.paste = 'Þ'
  let g:airline_symbols.paste = '∥'
  let g:airline_symbols.whitespace = 'Ξ'

  " airline symbols
  let g:airline_left_sep = ''
  let g:airline_left_alt_sep = ''
  let g:airline_right_sep = ''
  let g:airline_right_alt_sep = ''
  let g:airline_symbols.branch = ''
  let g:airline_symbols.readonly = ''
  let g:airline_symbols.linenr = ''

  " vim wiki dark template
  let g:vimwiki_list = [{ 
          \ 'auto_export': 1,
          \ 'auto_header': 1,
          \ 'automatic_nested_syntaxes':1,
          \ 'custom_wiki2html': '${wiki2html}/bin/wiki2html.sh',
          \ 'path_html': '$HOME/Documents/Wiki/html',
          \ 'path': '$HOME/Documents/Wiki/src',
		  \ 'template_path': '$HOME/Documents/Wiki/templates/',
		  \ 'template_default': 'GitHub',
          \ 'template_ext': '.html5',
          \ 'syntax': 'markdown',
          \ 'css_name': 'none.css',
          \ 'ext': '.md'}]

  let g:vimwiki_hl_headers = 1
  let g:vimwiki_ext2syntax = {'.md': 'markdown'}          
  let g:vimwiki_markdown_link_ext = 1


  " add the pre tag for inserting code snippets
  " let g:vimwiki_valid_html_tags = 'b,i,s,u,sub,sup,kbd,br,hr,pre,script'  
''
