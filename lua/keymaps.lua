-- Vim commentary emulation
vim.keymap.set('x', 'gc', '<Plug>VSCodeCommentary', {
  desc = '[VSCommentary]: Start comment action with word objects'
})
vim.keymap.set('n', 'gc', '<Plug>VSCodeCommentary', {
  desc = '[VSCommentary]: Start comment action with word objects'
})
vim.keymap.set('o', 'gc', '<Plug>VSCodeCommentary', {
  desc = '[VSCommentary]: Start comment action with word objects'
})
vim.keymap.set('n', 'gcc', '<Plug>VSCodeCommentaryLine', {
  desc = '[VSCommentary]: Toggle comment line under the cursor'
})

-- Ctrl+Shift+Up/Down to move up and down
-- vim.keymap.set('n', '<C-S-Down>', ':m .+1<cr>==',
--   { desc = 'Move line under the cursor down', silent = true })
-- vim.keymap.set('n', '<C-S-Up>', ':m .-2<cr>==',
--   { desc = 'Move line under the cursor up', silent = true })
-- vim.keymap.set('i', '<C-S-Down>', '<Esc>:m .+1<cr>==gi',
--   { desc = 'Move line under the cursor down', silent = true })
-- vim.keymap.set('i', '<C-S-Up>', '<Esc>:m .-2<cr>==gi',
--   { desc = 'Move line under the cursor up', silent = true })
-- vim.keymap.set('v', '<C-S-Down>', ":m '>+1<cr>gv=gv",
--   { desc = 'Move line under the cursor down', silent = true })
-- vim.keymap.set('v', '<C-S-Up>', ":m '<-2<cr>gv=gv",
--   { desc = 'Move line under the cursor up', silent = true })

-- ]<End> or ]<Home> move current line to the end or the begin of current buffer
vim.keymap.set('n', ']<End>', 'ddGp``',
  { desc = 'Move line to end of the buffer', noremap = true, silent = true })
vim.keymap.set('n', ']<Home>', 'ddggP``',
  { desc = 'Move line to start of the buffer', noremap = true, silent = true })
vim.keymap.set('v', ']<End>', 'dGp``',
  { desc = 'Move line to end of the buffer', noremap = true, silent = true })
vim.keymap.set('v', ']<Home>', 'dggP``',
  { desc = 'Move line to start of the buffer', noremap = true, silent = true })

-- Select blocks after indenting
vim.keymap.set('x', '<', '<gv',
  { desc = 'Reselect visual block after reducing indenting', noremap = true })
vim.keymap.set('x', '>', '>gv|',
  { desc = 'Reselect visual block after increasing indenting', noremap = true })

-- Use tab for indenting in visual mode
vim.keymap.set('x', '<Tab>', '>gv|',
  { desc = 'Increase indentation of selected block', noremap = true })
vim.keymap.set('x', '<S-Tab>', '<gv',
  { desc = 'Decrease indentation of selected block', noremap = true })
vim.keymap.set('n', '>', '>>_',
  { desc = 'Increase indentation of line', noremap = true })
vim.keymap.set('n', '<', '<<_',
  { desc = 'Decrease indentation of line', noremap = true })

-- smart up and down
vim.keymap.set('n', '<down>', 'gj',
  { desc = 'Move down in wrapped lines', silent = true, remap = true })
vim.keymap.set('n', '<up>', 'gk',
  { desc = 'Move up in wrapped lines', silent = true, remap = true })
-- nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
-- nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

-- Fast saving
vim.keymap.set('n', '<C-s>', ':<C-u>w<CR>',
  { desc = 'Save buffer with ctrl-s', noremap = true })
vim.keymap.set('v', '<C-s>', ':<C-u>w<CR>',
  { desc = 'Save buffer with ctrl-s', noremap = true })
vim.keymap.set('c', '<C-s>', '<C-u>w<CR>',
  { desc = 'Save buffer with ctrl-s', noremap = true })

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

-- VimSmoothie maps
vim.keymap.set('v', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  desc = '[VimSmoothie] Move down (ctrl-d)',
  noremap = true,
})
vim.keymap.set('n', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  desc = '[VimSmoothie] Move down (ctrl-d)',
  noremap = true,
})
vim.keymap.set('v', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  desc = '[VimSmoothie] Move up (ctrl-d)',
  noremap = true,
})
vim.keymap.set('n', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  desc = '[VimSmoothie] Move up (ctrl-d)',
  noremap = true,
})

vim.cmd('source ' .. '~/vim-config/utils/clipboard.vim')

-- Map clipboard functions
vim.keymap.set('x', '<Leader>y', ':<C-u>call clipboard#yank()<cr>',
  {
    desc = 'Yank selection to system clipboard',
    silent = true,
    noremap = true
  })
vim.keymap.set('n', '<Leader>p', 'clipboard#paste("p")',
  {
    desc = 'Paste content of system clipboard after the cursor',
    expr = true,
    noremap = true
  })
vim.keymap.set('n', '<Leader>P', 'clipboard#paste("P")',
  {
    desc = 'Paste content of system clipboard after the cursor',
    expr = true,
    noremap = true
  })
vim.keymap.set('x', '<Leader>p', 'clipboard#paste("p")',
  {
    desc = 'Paste content of system clipboard after the cursor',
    expr = true,
    noremap = true
  })
vim.keymap.set('x', '<Leader>P', 'clipboard#paste("P")',
  {
    desc = 'Paste content of system clipboard after the cursor',
    expr = true,
    noremap = true
  })

-- Clean trailing whitespace in file
vim.keymap.set('n', '<Leader>cc', ':%s/\\s\\+$//e<cr>', {
  desc = 'Clear trailing whitespace in file',
  noremap = true,
  silent = true,
})
-- Clean carriage returns '^M'
vim.keymap.set('n', '<Leader>cr', ':%s/\\r$//g<cr>', {
  desc = 'Clear carriage return characters (^M)',
  noremap = true,
  silent = true,
})
-- " Quick buffer overview an completion to change
vim.keymap.set('n', 'gb', ':ls<cr>:b<space>', {
  desc = 'List open buffers and set command mode for quick navigation',
  noremap = true,
})

-- " Move between buffers with tab
-- NOTE: disabled for issues on vscode handling of buffer next/prev
-- vim.keymap.set('n', '<tab>', ':bn<cr>', {
--   desc = 'Move to next buffer',
--   noremap = true,
--   silent = true,
-- })
-- vim.keymap.set('n', '<s-tab>', ':bN<cr>', {
--   desc = 'Move to previous buffer',
--   noremap = true,
--   silent = true,
-- })

-- vim-asterisk
vim.keymap.set({ 'n', 'v', 'o' }, '*', '<Plug>(asterisk-*)', {
  desc = '[Asterisk] Select word under the cursor *'
})
vim.keymap.set({ 'n', 'v', 'o' }, '#', '<Plug>(asterisk-#)', {
  desc = '[Asterisk] Select word under the cursor #'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'g*', '<Plug>(asterisk-g*)', {
  desc = '[Asterisk] Select word under the cursor g*'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'g#', '<Plug>(asterisk-g#)', {
  desc = '[Asterisk] Select word under the cursor g#'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'z*', '<Plug>(asterisk-z*)', {
  desc = '[Asterisk] Select word under the cursor * (preserve position)'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'gz*', '<Plug>(asterisk-gz*)', {
  desc = '[Asterisk] Select word under the cursor # (preserve position)'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'z#', '<Plug>(asterisk-z#)', {
  desc = '[Asterisk] Select word under the cursor g* (preserve position)'
})
vim.keymap.set({ 'n', 'v', 'o' }, 'gz#', '<Plug>(asterisk-gz#)', {
  desc = '[Asterisk] Select word under the cursor g# (preserve position)'
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


-- Vscode actions -- LSP like bindings
local vscode = require('vscode')

-- Go to implementation mappings
vim.keymap.set({ 'n', 'x' }, 'gI', function()
  vscode.action('editor.action.goToImplementation')
end, {
  desc = '[VSCode] Show implementations',
  noremap = true,
})
vim.keymap.set({ 'n', 'x' }, 'gi', function()
  vscode.action('editor.action.peekImplementation')
end, {
  desc = '[VSCode] Peak implementations',
  noremap = true,
})
vim.keymap.set('n', '<space>rn', function ()
  vscode.action('editor.action.rename')
end, {
  desc = '[VSCode] Rename symbol',
  noremap = true,
})

-- Show references
vim.keymap.set({ 'n', 'x' }, 'gr', function()
  vscode.action('editor.action.referenceSearch.trigger')
end, {
  desc = '[VSCode] Show references',
  noremap = true,
})

-- Format document
vim.keymap.set('n', '<space>f', function()
  vscode.action('editor.action.formatDocument')
end, {
  desc = '[VSCode] Format Document',
  noremap = true,
})


-- Open reference in vertical split
vim.keymap.set('n', 'gv', function()
  vscode.action('editor.action.revealDefinitionAside')
end, {
  desc = '[VSCode] Show definition in vertical split',
  noremap = true,
})

-- Hunk next
vim.keymap.set('n', '<space>nh', function ()
  vscode.action('workbench.action.editor.nextChange')
end)

-- Hunk next
vim.keymap.set('n', '<space>nH', function ()
  vscode.action('workbench.action.editor.previousChange')
end)

-- Diagnostic next
vim.keymap.set('n', ']d', function()
  vscode.action('editor.action.marker.next')
end, {
  desc = '[VSCode] Go to next diagnostic: error, warning, info',
  noremap = true,
})
-- Diagnostic prev
vim.keymap.set('n', '[d', function()
  vscode.action('editor.action.marker.prev')
end, {
  desc = '[VSCode] Go to previous diagnostic: error, warning, info',
  noremap = true,
})

-- Go to next merge conflict
vim.keymap.set('n', ']n', function ()
  vscode.action('merge-conflict.next')
end, { desc = '[VSCode] Go to next merge conflict' })

-- Go to prev merge conflict
vim.keymap.set('n', '[n', function ()
  vscode.action('merge-conflict.previous')
end, { desc = '[VSCode] Go to prev merge conflict' })

-- Action marker next/prev doesn't support moving per specific levels
-- error/warning/info/hint etc. So we duplicate the common case for complitness.
-- Diagnostic next
vim.keymap.set('n', '<space>ne', function()
  vscode.action('editor.action.marker.next')
end, {
  desc = '[VSCode] Go to next diagnostic: error, warning, info',
  noremap = true,
})
-- Diagnostic prev
vim.keymap.set('n', '<space>nE', function()
  vscode.action('editor.action.marker.prev')
end, {
  desc = '[VSCode] Go to previous diagnostic: error, warning, info',
  noremap = true,
})

-- also exists go to next and prev in same file:
-- editor.action.marker.nextInFiles and
-- editor.action.marker.prevInFiles

-- Code Actions (Quickfix)
vim.keymap.set({ 'n', 'x' }, '<space>ca', function()
  vscode.action('editor.action.quickFix')
end, {
  desc = '[VSCode] Open editor actions',
  noremap = true,
})


-- Fold Toggle
vim.keymap.set('n', 'za', function()
  vscode.action('editor.toggleFold')
end, {
  desc = '[VSCode] Toggle fold',
  noremap = true,
})

-- Below is the function in vimscript
-- function! s:manageEditorSize(...)
--     let count = a:1
--     let to = a:2
--     for i in range(1, count ? count : 1)
--         call VSCodeNotify(to ==# 'increase' ? 'workbench.action.increaseViewSize' : 'workbench.action.decreaseViewSize')
--     endfor
-- endfunction

---@param count number
---@param action string
local manageEditorSize = function(count, action)
  for _ in pairs(vim.fn.range(1, count ~= 0 and count or 1)) do
    vscode.action(action)
  end
end

-- Window resize vsplit
vim.keymap.set({ 'n', 'x' }, '<A-.>', function()
  manageEditorSize(vim.v.count, 'workbench.action.increaseViewWidth')
end, {
  desc = '[VSCode] Increase editor window width'
})
vim.keymap.set({ 'n', 'x' }, '<A-,>', function()
  manageEditorSize(vim.v.count, 'workbench.action.decreaseViewWidth')
end, {
  desc = '[VSCode] Decrease editor window width'
})

-- Window resize split
vim.keymap.set({ 'n', 'x' }, '<A-t>', function()
  manageEditorSize(vim.v.count, 'workbench.action.increaseViewHeight')
end, {
  desc = '[VSCode] Increase editor window height'
})
vim.keymap.set({ 'n', 'x' }, '<A-s>', function()
  manageEditorSize(vim.v.count, 'workbench.action.decreaseViewHeight')
end, {
  desc = '[VSCode] Decrease editor window height'
})

