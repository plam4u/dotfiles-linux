syntax on
filetype plugin indent on
colorscheme slate
set ts=4 sts=4 sw=4 noet aw incsearch nohls scs sb spr nobk noswf noudf cul mouse=a

let mapleader = " "
vnoremap y y:call system(expand("~/.local/bin/vim-copy"), @")<cr>
nnoremap H :bp<cr>
nnoremap L :bn<cr>
inoremap jk <esc>
inoremap kj <esc>
nnoremap <leader>ls :ls<cr>
nnoremap <leader>bd :bd<cr>
nnoremap <leader>so :so ~/.vimrc<cr>
nnoremap <leader>w :w<cr>
nnoremap <leader>q :q<cr>
nnoremap <leader>x :wqa<cr>
nnoremap <leader>e :e %:p:h<cr>
nnoremap <leader>r :Rexplore<cr>
