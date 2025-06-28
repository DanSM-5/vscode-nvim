" Close current buffer without affecting window layout
" Ref: https://vim.fandom.com/wiki/Deleting_a_buffer_without_closing_the_window

if exists('g:loaded_bclose')
  finish
endif

let g:loaded_bclose = 1

" Do not load in vscode mode
if exists('g:vscode')
  finish
endif


" Renamed Kwbd command to BCloseCurrent
command! BCloseCurrent call bda#kwbd(1)
command! -bang -bar BCloseOthers call bda#bdo(<bang>0)
command! -bang -bar BCloseAllBuffers call bda#bda(<bang>0)

nnoremap <silent> <Plug>BCloseCurrent :<C-u>BCloseCurrent<CR>
nnoremap <silent> <Plug>BCloseOthers :<C-u>BCloseOthers<CR>
nnoremap <silent> <Plug>BCloseAllBuffers :<C-u>BCloseAllBuffers<CR>

