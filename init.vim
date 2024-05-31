
" let g:vscode_loaded = 1
" VSCode extension

" Change location of shada files for VSCode to avoid conflicts
" with nvim profile in terminal
set shada+='1000,n$HOME/.cache/vscode-nvim/main.shada

" Make nocompatible explisit
set nocompatible

" Vim commentary emulation
xmap gc  <Plug>VSCodeCommentary
nmap gc  <Plug>VSCodeCommentary
omap gc  <Plug>VSCodeCommentary
nmap gcc <Plug>VSCodeCommentaryLine

" Useful keybindings
" Replace word under the cursor with content of register 0
nmap <leader>v ciw<C-r>0<ESC>

" Camel case motion keybindings
let g:camelcasemotion_key = '<leader>'
" Vim-Asterisk keep cursor position under current letter with
let g:asterisk#keeppos = 1

""Ctrl+Shift+Up/Down to move up and down
nmap <silent><C-S-Down> :m .+1<CR>==
nmap <silent><C-S-Up> :m .-2<CR>==
imap <silent><C-S-Down> <Esc>:m .+1<CR>==gi
imap <silent><C-S-Up> <Esc>:m .-2<CR>==gi
vmap <silent><C-S-Down> :m '>+1<CR>gv=gv
vmap <silent><C-S-Up> :m '<-2<CR>gv=gv

" ]<End> or ]<Home> move current line to the end or the begin of current buffer
nnoremap <silent>]<End> ddGp``
nnoremap <silent>]<Home> ddggP``
vnoremap <silent>]<End> dGp``
vnoremap <silent>]<Home> dggP``

" Select blocks after indenting
xnoremap < <gv
xnoremap > >gv|

" Use tab for indenting in visual mode
xnoremap <Tab> >gv|
xnoremap <S-Tab> <gv
nnoremap > >>_
nnoremap < <<_

" smart up and down
nmap <silent><DOWN> gj
nmap <silent><UP> gk
" nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
" nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

" Fast saving
nnoremap <C-s> :<C-u>w<CR>
vnoremap <C-s> :<C-u>w<CR>
cnoremap <C-s> <C-u>w<CR>

" System copy maps
source ~/.SpaceVim.d/utils/system-copy-maps.vim

"" move selected lines up one line
"xnoremap <A-Up> :m-2<CR>gv=gv
"" move selected lines down one line
"xnoremap <A-Down> :m'>+<CR>gv=gv
"" move current line up one line
"noremap <A-Up> :<C-u>m-2<CR>==
"" move current line down one line
"nnoremap <A-Down> :<C-u>m+<CR>==
"" move current line up in insert mode
"inoremap <A-Up> <Esc>:m .-2<CR>==gi
"" move current line down in insert mode
"inoremap <A-Down> <Esc>:m .+1<CR>==gi

" Load plugins
set runtimepath^=~/.cache/vimfiles/repos/github.com/DanSM-5/vim-system-copy
set runtimepath^=~/.config/vscode-nvim/plugins/vim-repeat
set runtimepath^=~/.cache/vimfiles/repos/github.com/bkad/CamelCaseMotion
set runtimepath^=~/.cache/vimfiles/repos/github.com/tpope/vim-surround
" set runtimepath^=~/.cache/vimfiles/repos/github.com/christoomey/vim-sort-motion
set runtimepath^=~/.cache/vimfiles/repos/github.com/kreskij/Repeatable.vim
set runtimepath^=~/.cache/vimfiles/repos/github.com/haya14busa/vim-asterisk
set runtimepath^=~/.config/vscode-nvim/plugins/vim-smoothie

source ~/.cache/vimfiles/repos/github.com/DanSM-5/vim-system-copy/plugin/system_copy.vim
source ~/.cache/vimfiles/repos/github.com/bkad/CamelCaseMotion/plugin/camelcasemotion.vim
source ~/.cache/vimfiles/repos/github.com/tpope/vim-surround/plugin/surround.vim
" source ~/.cache/vimfiles/repos/github.com/christoomey/vim-sort-motion/sort_motion.vim
source ~/.cache/vimfiles/repos/github.com/kreskij/Repeatable.vim/plugin/repeatable.vim
source ~/.cache/vimfiles/repos/github.com/haya14busa/vim-asterisk/plugin/asterisk.vim
source ~/.config/vscode-nvim/plugins/vim-smoothie/plugin/smoothie.vim

" Move line up/down
" Require repeatable.vim
Repeatable nnoremap mlu :<C-U>m-2<CR>==
Repeatable nnoremap mld :<C-U>m+<CR>==

if $IS_WINSHELL == 'true'
  " Windows specific
  set shell=cmd
  set shellcmdflag=/c

  " Set system_copy variables
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'pbcopy.exe'
elseif has('wsl') && $IS_WSL1 == 'true'
  " Set system_copy variables
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'pbcopy.exe'
elseif !empty($DISPLAY) && executable('xsel')
  let g:system_copy#copy_command = 'xsel -i -b'
  let g:system_copy#paste_command = 'xsel -o -b'
elseif !empty($DISPLAY) && executable('xclip')
  let g:system_copy#copy_command = 'xclip -i -selection clipboard'
  let g:system_copy#paste_command = 'xclip -o -selection clipboard'
elseif !empty($WAYLAND_DISPLAY) && executable('wl-copy') && executable('wl-paste')
  let g:system_copy#copy_command = 'wl-copy --foreground --type text/plain'
  let g:system_copy#paste_command = 'wl-paste --no-newline'
elseif has('mac')
  " Set system_copy variables
  let g:system_copy#paste_command = 'pbpaste'
  let g:system_copy#copy_command = 'pbcopy'
elseif executable('pbcopy.exe')
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'pbcopy.exe'
endif

" Prevent open dialog
let g:system_copy_silent = 1

" Load utility clipboard functions
source ~/.SpaceVim.d/utils/clipboard.vim

" Map clipboard functions
xnoremap <silent> <Leader>y :<C-u>call clipboard#yank()<cr>
nnoremap <expr> <Leader>p clipboard#paste('p')
nnoremap <expr> <Leader>P clipboard#paste('P')
xnoremap <expr> <Leader>p clipboard#paste('p')
xnoremap <expr> <Leader>P clipboard#paste('P')

" Clean trailing whitespace in file
nnoremap <silent> <Leader>c :%s/\s\+$//e<cr>
" Clean carriage returns '^M'
nnoremap <silent> <Leader>r :%s/\r$//g<cr>
" Quick buffer overview an completion to change
nnoremap gb :ls<CR>:b<Space>
" Move between buffers with tab
nnoremap <silent> <tab> :bn<cr>
nnoremap <silent> <s-tab> :bN<cr>

" vim-asterisk
map *   <Plug>(asterisk-*)
map #   <Plug>(asterisk-#)
map g*  <Plug>(asterisk-g*)
map g#  <Plug>(asterisk-g#)
map z*  <Plug>(asterisk-z*)
map gz* <Plug>(asterisk-gz*)
map z#  <Plug>(asterisk-z#)
map gz# <Plug>(asterisk-gz#)

" Set 'stay' behavior by default
" map *  <Plug>(asterisk-z*)
" map #  <Plug>(asterisk-z#)
" map g* <Plug>(asterisk-gz*)
" map g# <Plug>(asterisk-gz#)

" " Down
" nnoremap <C-d> <C-d>zz
" " Up
" nnoremap <C-u> <C-u>zz
" " Forwards
" nnoremap <C-f> <C-f>zz
" " Backwards
" nnoremap <C-b> <C-b>zz
" nnoremap <PageUp> <PageUp>zz
" nnoremap <PageDown> <PageDown>zz
" nnoremap <S-Up> <S-Up>zz
" nnoremap <S-Down> <S-Down>zz
