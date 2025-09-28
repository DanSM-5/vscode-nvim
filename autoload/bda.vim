" Ref: https://github.com/alexandermckay/bda
" Original credits
" Plugin: BDA - Buffer Delete All
" Description: Reset the buffer list whilst preserving your layout
" Author: Alexander McKay
" Version: 1.0.0

if exists('g:vscode')
  finish
endif

function bda#CreateNoNameBuffer()
  enew
endfunction

function bda#GetNoNameBufferNumber()
  call bda#CreateNoNameBuffer()
  return bufnr('%')
endfunction

function bda#SwitchWindowsToBuffer(target_buffer_number)
  for winnr in range(1, winnr('$'))
    execute winnr . 'wincmd w'
    execute 'buffer' a:target_buffer_number
  endfor
endfunction

function bda#DeleteOtherNamedBuffers(exclude_buffer_number)
  for buf in getbufinfo({'buflisted': 1})
    if buf.bufnr != a:exclude_buffer_number
      execute 'bdelete' buf.bufnr
    endif
  endfor
endfunction

function! bda#bda(...)
  let preserve_windows = exists('a:1') ? a:1 : 0
  if preserve_windows
    let no_name_buffer_number = bda#GetNoNameBufferNumber()
    call bda#SwitchWindowsToBuffer(no_name_buffer_number)
    call bda#DeleteOtherNamedBuffers(no_name_buffer_number)
    return
  endif

  " Just close everything, windows included
  execute ':%bd'
endfunction

function! bda#bdo(...) abort
  let preserve_windows = exists('a:1') ? a:1 : 0
  if !preserve_windows
    execute ':%bd|e#|bn|bd'
    return
  endif

  let current_file = expand('%:p')
  " let current_buff = bufnr('%')
  call bda#bda(preserve_windows)
  " let no_name_buffer_number = bda#GetNoNameBufferNumber()
  " if !clear_windows
  "   call bda#SwitchWindowsToBuffer(no_name_buffer_number)
  "   " redraw!
  " endif
  " call bda#DeleteOtherNamedBuffers(current_buff)

  " NOTE: TSContext breaks without the sleep
  " redraw is added just to nicely show a change on screen
  redraw!
  sleep 1
  execute 'edit '.current_file
endfunction



" Close current buffer without affecting window layout
" Ref: https://vim.fandom.com/wiki/Deleting_a_buffer_without_closing_the_window

" NOTE: Comments from author
" here is a more exotic version of my original Kwbd script
" delete the buffer; keep windows; create a scratch buffer if no buffers left

function bda#kwbd(kwbdStage)
  if(a:kwbdStage == 1)
    if(&modified)
      let answer = confirm("This buffer has been modified. Do you want to save before closing?", "&Yes\n&No\n&Cancel", 2)

      " Save buffer first
      if (answer == 1)
        write
      " Cancel operation
      elseif (answer == 3)
        return
      endif

      " answer == 2, continue closing without saving
    endif
    if(!buflisted(winbufnr(0)))
      bd!
      return
    endif
    let s:kwbdBufNum = bufnr("%")
    let s:kwbdWinNum = winnr()
    windo call bda#kwbd(2)
    execute s:kwbdWinNum . 'wincmd w'
    let s:buflistedLeft = 0
    let s:bufFinalJump = 0
    let l:nBufs = bufnr("$")
    let l:i = 1
    while(l:i <= l:nBufs)
      if(l:i != s:kwbdBufNum)
        if(buflisted(l:i))
          let s:buflistedLeft = s:buflistedLeft + 1
        else
          if(bufexists(l:i) && !strlen(bufname(l:i)) && !s:bufFinalJump)
            let s:bufFinalJump = l:i
          endif
        endif
      endif
      let l:i = l:i + 1
    endwhile
    if(!s:buflistedLeft)
      if(s:bufFinalJump)
        windo if(buflisted(winbufnr(0))) | execute "b! " . s:bufFinalJump | endif
      else
        enew
        let l:newBuf = bufnr("%")
        windo if(buflisted(winbufnr(0))) | execute "b! " . l:newBuf | endif
      endif
      execute s:kwbdWinNum . 'wincmd w'
    endif
    if(buflisted(s:kwbdBufNum) || s:kwbdBufNum == bufnr("%"))
      execute "bd! " . s:kwbdBufNum
    endif
    if(!s:buflistedLeft)
      set buflisted
      set bufhidden=delete
      set buftype=
      setlocal noswapfile
    endif
  else
    if(bufnr("%") == s:kwbdBufNum)
      let prevbufvar = bufnr("#")
      if(prevbufvar > 0 && buflisted(prevbufvar) && prevbufvar != s:kwbdBufNum)
        b #
      else
        bn
      endif
    endif
  endif
endfunction

" TODO: Use shorter names?
" command! -bang -bar Bda call bda#bda(<bang>0)
" cabbrev bda Bda
