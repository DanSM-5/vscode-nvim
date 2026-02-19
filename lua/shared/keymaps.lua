local nxo = { 'n', 'x', 'o' }

-- Search in visual selected area
vim.keymap.set('x', '/', '<esc>/\\%V', { desc = '[Nvim] Search in selected area', noremap = true })
vim.keymap.set('n', 'g/', '<esc>/\\%V', { desc = '[Nvim] Search in last selected area', noremap = true })

-- Indent text object
-- :h indent-object
-- vim.keymap.set('x', 'ii', '<Plug>(indent-object_linewise-none)', {
--   remap = true,
--   desc = '[Indent-Object] Select inner indent'
-- })
-- vim.keymap.set('o', 'ii', '<Plug>(indent-object_blockwise-none)', {
--   remap = true,
--   desc = '[Indent-Object] O-Pending inner indent (blockwise)'
-- })
-- vim.keymap.set('o', 'ii', '<Plug>(indent-object_linewise-none)', {
--   remap = true,
--   desc = '[Indent-Object] O-Pending inner indent'
-- })

-- vim.keymap.set('x', 'ia', '<Plug>(indent-object_linewise-both)', {
--   remap = true,
--   desc = '[Indent-Object] Select around indent'
-- })
-- vim.keymap.set('o', 'ia', '<Plug>(indent-object_blockwise-both)', {
--   remap = true,
--   desc = '[Indent-Object] O-Pending around indent (blockwise)'
-- })
-- vim.keymap.set('o', 'ia', '<Plug>(indent-object_linewise-both)', {
--   remap = true,
--   desc = '[Indent-Object] O-Pending around indent'
-- })

-- Replace with register keymaps
vim.keymap.set('n', 'cr', '<Plug>ReplaceWithRegisterOperator', { desc = '[Register] Replace with register operator' })
vim.keymap.set('n', 'crr', '<Plug>ReplaceWithRegisterLine', { desc = '[Register] Replace with register line' })
vim.keymap.set('x', 'cr', '<Plug>ReplaceWithRegisterVisual', { desc = '[Register] Replace with register in visual mode' })
pcall(vim.keymap.del, 'n', 'grr')

-- Yank paths
vim.keymap.set('n', '<leader>yf', "<cmd>let @+=expand('%:.')<cr>", { desc = '[Yank] Copy path to file (relative)' })
vim.keymap.set('n', '<leader>yF', "<cmd>let @+=expand('%:p')<cr>", { desc = '[Yank] Copy path to file (absolute)' })
vim.keymap.set('n', '<leader>yp', "<cmd>let @+=expand('%:.:h')<cr>", { desc = '[Yank] Copy path to directory (relative)' })
vim.keymap.set('n', '<leader>yP', "<cmd>let @+=expand('%:p:h')<cr>", { desc = '[Yank] Copy path to directory (absolute)' })
vim.keymap.set('n', '<leader>yn', "<cmd>let @+=expand('%:t')<cr>", { desc = '[Yank] Copy name of file' })

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

-- Cd to current project or active buffer directory
vim.keymap.set('n', '<leader>cd', function()
  vim.cmd.Bcd()
end, { noremap = true, desc = 'Change root directory of repo or file directory' })

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

-- Search in visual selected area
vim.keymap.set('x', '/', '<esc>/\\%V', { noremap = true, desc = '[search] Narrow search to visual selection' })
vim.keymap.set('n', 'g/', '<esc>/\\%V', { noremap = true, desc = '[search] Narrow search to visual selection' })
vim.keymap.set('n', '<leader>sv', function ()
  local start_l = vim.fn.line('w0')
  local end_l = vim.fn.line('w$')
  vim.cmd(string.format('%dmark < | %dmark >', start_l, end_l))
  return '/\\%V'
end, { noremap = true, expr = true, desc = '[search] search current viewport window' })

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
vim.keymap.set(
  'n',
  '<leader>vp',
  'ciw<C-r>0<esc>',
  { desc = 'Paste text replacing word under the cursor', noremap = true }
)

-- Move in jumplist
-- vim.keymap.set('n', '<A-i>', '<C-i>', { noremap = true, desc = 'Jumplist newer' })
-- vim.keymap.set('n', '<A-o>', '<C-o>', { noremap = true, desc = 'Jumplist older' })

-- : Repeatable keymaps : *************************************************

local repeat_motion = require('utils.repeat_motion')

-- Repeat with ',' and ';'
repeat_motion.set_motion_keys()

local create_dot_map = repeat_motion.repeat_dot_map
local create_repeatable_pair = repeat_motion.create_repeatable_pair
local repeat_pair = repeat_motion.repeat_pair

local next_matching_bracket, prev_matching_bracket = create_repeatable_pair(function()
  ---@diagnostic disable-next-line Diagnostic have the wrong function signature for searchpair
  vim.fn.searchpair('{', '', '}')
end, function()
  ---@diagnostic disable-next-line Diagnostic have the wrong function signature for searchpair
  vim.fn.searchpair('{', '', '}', 'b')
end)
local next_bracket_pair, prev_bracket_pair = create_repeatable_pair(function()
  vim.fn.search('[\\[\\]{}()<>]', 'w')
end, function()
  vim.fn.search('[\\[\\]{}()<>]', 'wb')
end)
vim.keymap.set(
  'n',
  ']}',
  next_bracket_pair,
  { desc = '[Bracket]: Go to next bracket pair', silent = true, noremap = true }
)
vim.keymap.set(
  'n',
  '[}',
  prev_bracket_pair,
  { desc = '[Bracket]: Go to previous bracket pair', silent = true, noremap = true }
)
vim.keymap.set(
  'n',
  ']{',
  next_matching_bracket,
  { desc = '[Bracket]: Go to next matching bracket', silent = true, noremap = true }
)
vim.keymap.set(
  'n',
  '[{',
  prev_matching_bracket,
  { desc = '[Bracket]: Go to previous matching bracket', silent = true, noremap = true }
)

-- Dot repeatable maps
create_dot_map('nnoremap <A-y> :<C-U>t.<cr>')
create_dot_map('nnoremap <A-e> :<C-U>t-1<cr>')
-- Better to stick with shift+alt+up/down
-- create_dot_map('inoremap <A-y> <esc>:<C-U>t-1<cr>a')
-- create_dot_map('inoremap <A-e> <esc>:<C-U>t-1<cr>a')

local move_line_end, move_line_almost_end = create_repeatable_pair(function()
  vim.cmd.normal([[ddGp``]])
end, function()
  vim.cmd.normal([[ddGP``]])
  -- vim.cmd.normal([[ddggP``]])
end)
local move_line_start, move_line_almost_start = create_repeatable_pair(function()
  vim.cmd.normal([[ddggP``]])
end, function()
  vim.cmd.normal([[ddggp``]])
end)

-- move current line to the end or the begin of current buffer
vim.keymap.set('n', ']<End>', move_line_end, { desc = 'Move line to end of the buffer', noremap = true, silent = true })
vim.keymap.set(
  'n',
  '[<End>',
  move_line_almost_end,
  { desc = 'Move line to the second last line in the buffer', noremap = true, silent = true }
)
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

------Move to the next indent scope using direction
------@param direction boolean
---local move_scope = function(direction)
---  local ok, mini_indent = pcall(require, 'mini.indentscope')
---
---  if not ok then
---    vim.notify('mini_indent not found', vim.log.levels.WARN)
---    return
---  end
---
---  local dir = direction and 'bottom' or 'top'
---
---  mini_indent.operator(dir)
---end
----- TODO: Consider if overriding this defaults is correct
---repeat_pair({
---  keys = 'i',
---  mode = nxo,
---  on_forward = function()
---    move_scope(true)
---  end,
---  on_backward = function()
---    move_scope(false)
---  end,
---  desc_forward = '[MiniIndent] Go to indent scope top',
---  desc_backward = '[MiniIndent] Go to indent scope bottom',
---})

---@type fun(), fun()
local indent_scope_top_n, indent_scope_bottom_n
---@type fun(), fun()
local indent_scope_top_xo, indent_scope_bottom_xo
local get_indent_scope = function (...)
  local blink_indent_motion = require('blink.indent.motion')
  return blink_indent_motion.operator(...)
end

local indent_bottom_n, indent_top_n = create_repeatable_pair(function()
  indent_scope_bottom_n = indent_scope_bottom_n or get_indent_scope('bottom', true)
  indent_scope_bottom_n()
end, function()
  indent_scope_top_n = indent_scope_top_n or get_indent_scope('top', true)
  indent_scope_top_n()
end)
local indent_bottom_xo, indent_top_xo = create_repeatable_pair(function()
  indent_scope_bottom_xo = indent_scope_bottom_xo or get_indent_scope('bottom')
  indent_scope_bottom_xo()
end, function()
  indent_scope_top_xo = indent_scope_top_xo or get_indent_scope('top')
  indent_scope_top_xo()
end)

vim.keymap.set(
  'n',
  '[i',
  indent_top_n,
  { desc = '[indent] Go to indent scope top', noremap = true, silent = true }
)
vim.keymap.set(
  'n',
  ']i',
  indent_bottom_n,
  { desc = '[indent] Go to indent scope bottom', noremap = true, silent = true }
)
vim.keymap.set(
  { 'x', 'o' },
  '[i',
  indent_top_xo,
  { desc = '[indent] Go to indent scope top', noremap = true, silent = true }
)
vim.keymap.set(
  { 'x', 'o' },
  ']i',
  indent_bottom_xo,
  { desc = '[indent] Go to indent scope bottom', noremap = true, silent = true }
)

local todo_next, todo_prev = create_repeatable_pair(function()
  local keywords = require('lib.fzf').todo_keywords
  local query = table.concat(keywords, '\\|')
  -- search('\(NOTE\|TODO\):', 'bw')
  vim.fn.search(string.format('\\(%s\\):', query), 'w')
end, function()
  local keywords = require('lib.fzf').todo_keywords
  local query = table.concat(keywords, '\\|')
  vim.fn.search(string.format('\\(%s\\):', query), 'bw')
end)

repeat_pair({
  keys = ':',
  desc_forward = '[TodoComments] Move to next todo comment',
  desc_backward = '[TodoComments] Move to previous todo comment',
  on_forward = todo_next,
  on_backward = todo_prev,
})
