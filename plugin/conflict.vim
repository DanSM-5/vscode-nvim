if exists('g:loaded_conflict')
  finish
endif

let g:loaded_conflict = 1

" Do not load in vscode mode
if exists('g:vscode')
  finish
endif

nnoremap <silent> <Plug>JumpconflictContextPrevious :<C-U>call jump_conflict#context(1)<CR>
nnoremap <silent> <Plug>JumpconflictContextNext     :<C-U>call jump_conflict#context(0)<CR>
xnoremap <silent> <Plug>JumpconflictContextPrevious :<C-U>exe 'normal! gv'<Bar>call jump_conflict#context(1)<CR>
xnoremap <silent> <Plug>JumpconflictContextNext     :<C-U>exe 'normal! gv'<Bar>call jump_conflict#context(0)<CR>
onoremap <silent> <Plug>JumpconflictContextPrevious :<C-U>call jump_conflict#contextMotion(1)<CR>
onoremap <silent> <Plug>JumpconflictContextNext     :<C-U>call jump_conflict#contextMotion(0)<CR>
