{} :       
''
  set nocompatible " use vim defaults

  set backspace=indent,eol,start " Allow backspacing over everything in insert mode
  let mapleader=","
  command! W :w " Seriously, guys. It's not like :W is bound to anything anyway.

  map <C-5> :noh<CR>

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
''
