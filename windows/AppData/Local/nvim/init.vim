
" Plugins
call plug#begin('~/AppData/Local/nvim/plugged')

Plug 'chriskempson/base16-vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jackguo380/vim-lsp-cxx-highlight'

call plug#end()

colorscheme base16-monokai-personal

" Enable/Disable vim text properties for vim-lsp-cxx-highlight
let g:lsp_cxx_hl_use_text_props = 0

" Set tabs to be 4 spaces wide
set tabstop=4
set shiftwidth=4
set noexpandtab
