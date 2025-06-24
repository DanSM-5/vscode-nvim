local nxo = { 'n', 'x', 'o' }

-- Search in visual selected area
vim.keymap.set('x', '/', '<esc>/\\%V', { desc = '[Nvim] Search in selected area', noremap = true })
vim.keymap.set('n', 'g/', '<esc>/\\%V', { desc = '[Nvim] Search in last selected area', noremap = true })

-- Indent text object
-- :h indent-object
vim.keymap.set('x', 'ii', '<Plug>(indent-object_linewise-none)', {
  remap = true,
  desc = '[Indent-Object] Select inner indent'
})
vim.keymap.set('o', 'ii', '<Plug>(indent-object_blockwise-none)', {
  remap = true,
  desc = '[Indent-Object] O-Pending inner indent'
})

-- Reselect visual blocks after indenting
vim.keymap.set('x', '<', '<gv', {
  noremap = true,
  desc = '[Indent] Reselect visual block after reduce indent',
})
vim.keymap.set('x', '>', '>gv|', {
  noremap = true,
  desc = '[Indent] Reselect visual block after increase indent',
})

-- Use tab for indenting in visual mode
vim.keymap.set('x', '<S-Tab>', '<gv', { desc = '[Indent] Decrease indentation of selected block', noremap = true })
vim.keymap.set('x', '<Tab>', '>gv|', { desc = '[Indent] Increase indentation of selected block', noremap = true })
vim.keymap.set('n', '>', '>>_', { desc = '[Indent] Increase indentation of line', noremap = true })
vim.keymap.set('n', '<', '<<_', { desc = '[Indent] Decrease indentation of line', noremap = true })


-- smart up and down
vim.keymap.set('n', '<down>', 'gj', { desc = '[Nav] Move down in wrapped lines', silent = true, remap = true })
vim.keymap.set('n', '<up>', 'gk', { desc = '[Nav] Move up in wrapped lines', silent = true, remap = true })
-- nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
-- nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

-- SystemCopy keybindings
vim.keymap.set('n', 'zy', '<Plug>SystemCopy', {
  desc = '[SystemCopy] Copy motion',
})
vim.keymap.set('x', 'zy', '<Plug>SystemCopy', {
  desc = '[SystemCopy] Copy motion',
})
vim.keymap.set('n', 'zY', '<Plug>SystemCopyLine', {
  desc = '[SystemCopy] Copy line under cursor',
})
vim.keymap.set('n', 'zp', '<Plug>SystemPaste', {
  desc = '[SystemCopy] Paste motion',
})
vim.keymap.set('x', 'zp', '<Plug>SystemPaste', {
  desc = '[SystemCopy] Paste motion',
})
vim.keymap.set('n', 'zP', '<Plug>SystemPasteLine', {
  desc = '[SystemCopy] Paste line below',
})

-- Map clipboard functions
vim.keymap.set('x', '<leader>y', ':<C-u>call clipboard#yank()<cr>', {
  desc = 'Yank selection to system clipboard',
  silent = true,
  noremap = true,
})
vim.keymap.set('n', '<leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('n', '<leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})


-- Clean trailing whitespace in file
vim.keymap.set('n', '<leader>cc', ':%s/\\s\\+$//e<cr>', {
  desc = 'Clear trailing whitespace in file',
  noremap = true,
  silent = true,
})
-- Clean carriage returns '^M'
vim.keymap.set('n', '<leader>cr', ':%s/\\r$//g<cr>', {
  desc = 'Clear carriage return characters (^M)',
  noremap = true,
  silent = true,
})


-- vim-asterisk
vim.keymap.set(nxo, '*', '<Plug>(asterisk-*)', {
  desc = '[Asterisk] Select word under the cursor *',
})
vim.keymap.set(nxo, '#', '<Plug>(asterisk-#)', {
  desc = '[Asterisk] Select word under the cursor #',
})
vim.keymap.set(nxo, 'g*', '<Plug>(asterisk-g*)', {
  desc = '[Asterisk] Select word under the cursor g*',
})
vim.keymap.set(nxo, 'g#', '<Plug>(asterisk-g#)', {
  desc = '[Asterisk] Select word under the cursor g#',
})
vim.keymap.set(nxo, 'z*', '<Plug>(asterisk-z*)', {
  desc = '[Asterisk] Select word under the cursor * (preserve position)',
})
vim.keymap.set(nxo, 'gz*', '<Plug>(asterisk-gz*)', {
  desc = '[Asterisk] Select word under the cursor # (preserve position)',
})
vim.keymap.set(nxo, 'z#', '<Plug>(asterisk-z#)', {
  desc = '[Asterisk] Select word under the cursor g* (preserve position)',
})
vim.keymap.set(nxo, 'gz#', '<Plug>(asterisk-gz#)', {
  desc = '[Asterisk] Select word under the cursor g# (preserve position)',
})

-- Set 'stay' behavior by default
-- map *  <Plug>(asterisk-z*)
-- map #  <Plug>(asterisk-z#)
-- map g* <Plug>(asterisk-gz*)
-- map g# <Plug>(asterisk-gz#)

-- -- Down
-- nnoremap <C-d> <C-d>zz
-- -- Up
-- nnoremap <C-u> <C-u>zz
-- -- Forwards
-- nnoremap <C-f> <C-f>zz
-- -- Backwards
-- nnoremap <C-b> <C-b>zz
-- nnoremap <PageUp> <PageUp>zz
-- nnoremap <PageDown> <PageDown>zz
-- nnoremap <S-Up> <S-Up>zz
-- nnoremap <S-Down> <S-Down>zz

-- " Delete marks in line under cursor
vim.keymap.set('n', '<leader>`d', function()
  require('utils.funcs').delete_marks_curr_line()
end, {
  desc = 'Remove marks on current line',
  noremap = true,
})


-- Reselect previous yank
-- This obscures default gV that prevents reselection of :vmenu commands
vim.keymap.set('n', 'gV', '`[v`]', { noremap = true, desc = 'Reselect last yank area' })


-- Copy from unnamed register to clipboard
vim.keymap.set('n', 'yd', function()
  require('utils.funcs').regmove('+', '"')
end, { noremap = true, desc = '[clipboard] Move content from unnamed register to clipboard' })
-- Copy from clipboard to unnamed register
vim.keymap.set('n', 'yD', function()
  require('utils.funcs').regmove('"', '+')
end, { noremap = true, desc = '[clipboard] Move clipboard content to unnamed register' })


-- Paste and replace word under cursor
vim.keymap.set('n', '<leader>vp', 'ciw<C-r>0<esc>',
  { desc = 'Paste text replacing word under the cursor', noremap = true })



-- : Repeatable keymaps : *************************************************


local repeat_motion = require('utils.repeat_motion')

-- Repeat with ',' and ';'
repeat_motion.set_motion_keys()

local create_dot_map = repeat_motion.repeat_dot_map
local create_repeatable_pair = repeat_motion.create_repeatable_pair

local next_matching_bracket, prev_matching_bracket = create_repeatable_pair(
  function()
    ---@diagnostic disable-next-line Diagnostic have the wrong function signature for searchpair
    vim.fn.searchpair('{', '', '}')
  end, function()
    ---@diagnostic disable-next-line Diagnostic have the wrong function signature for searchpair
    vim.fn.searchpair('{', '', '}', 'b')
  end
)
local next_bracket_pair, prev_bracket_pair = create_repeatable_pair(
  function()
    vim.fn.search('[\\[\\]{}()<>]', 'w')
  end, function()
    vim.fn.search('[\\[\\]{}()<>]', 'wb')
  end
)
vim.keymap.set('n', ']}', next_bracket_pair,
  { desc = '[Bracket]: Go to next bracket pair', silent = true, noremap = true })
vim.keymap.set('n', '[}', prev_bracket_pair,
  { desc = '[Bracket]: Go to previous bracket pair', silent = true, noremap = true })
vim.keymap.set('n', ']{', next_matching_bracket,
  { desc = '[Bracket]: Go to next matching bracket', silent = true, noremap = true })
vim.keymap.set('n', '[{', prev_matching_bracket,
  { desc = '[Bracket]: Go to previous matching bracket', silent = true, noremap = true })

-- Dot repeatable maps
create_dot_map('nnoremap <A-y> :<C-U>t.<cr>')
create_dot_map('nnoremap <A-e> :<C-U>t-1<cr>')
-- Better to stick with shift+alt+up/down
-- create_dot_map('inoremap <A-y> <esc>:<C-U>t-1<cr>a')
-- create_dot_map('inoremap <A-e> <esc>:<C-U>t-1<cr>a')

local move_line_end, move_line_almost_end = create_repeatable_pair(function ()
  vim.cmd.normal([[ddGp``]])
end, function ()
  vim.cmd.normal([[ddGP``]])
  -- vim.cmd.normal([[ddggP``]])
end)
local move_line_start, move_line_almost_start = create_repeatable_pair(function ()
  vim.cmd.normal([[ddggP``]])
end, function ()
  vim.cmd.normal([[ddggp``]])
end)

-- move current line to the end or the begin of current buffer
vim.keymap.set('n', ']<End>', move_line_end, { desc = 'Move line to end of the buffer', noremap = true, silent = true })
vim.keymap.set('n', '[<End>', move_line_almost_end,
  { desc = 'Move line to the second last line in the buffer', noremap = true, silent = true })
vim.keymap.set(
  'n',
  ']<Home>',
  move_line_almost_start,
  { desc = 'Move line to second line in the buffer', noremap = true, silent = true }
)
vim.keymap.set(
  'n',
  '[<Home>',
  move_line_start,
  { desc = 'Move line to start of the buffer', noremap = true, silent = true }
)
