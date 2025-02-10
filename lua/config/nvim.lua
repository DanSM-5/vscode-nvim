-- Set colorscheme
vim.cmd.colorscheme('slate')

-- Disable vim-smoothie remaps
vim.g.smoothie_no_default_mappings = 1
vim.opt.scrolloff = 5

vim.g.markdown_folding = 1

-- Mappings to help navigation
vim.keymap.set('n', '<c-p>', ':<C-u>GFiles<cr>', {
  noremap = true,
  desc = '[Fzf] Git files',
})

-- VimSmoothie remap
vim.keymap.set('v', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', '<S-down>', '<cmd>call smoothie#do("\\<C-D>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('v', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', '<S-up>', '<cmd>call smoothie#do("\\<C-U>")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('v', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})
vim.keymap.set('n', 'zz', '<Cmd>call smoothie#do("zz")<CR>', {
  noremap = true,
  desc = '[Smoothie] Scroll down',
})

-- Quickfix navigation
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zz', {
  noremap = true,
  desc = '[Quickfix] move next',
})
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zz', {
  noremap = true,
  desc = '[Quickfix] move previous',
})
-- Location list navigation
vim.keymap.set('n', '[l', '<cmd>lnext<cr>zz', {
  noremap = true,
  desc = '[Loclist] move next',
})
vim.keymap.set('n', ']l', '<cmd>lprev<cr>zz', {
  noremap = true,
  desc = '[Loclist] move previous',
})

-- Move between buffers with tab
vim.keymap.set('n', '<tab>', ':bn<cr>', { silent = true, noremap = true, desc = '[Buffer] Next buffer' })
vim.keymap.set('n', '<s-tab>', ':bN<cr>', { silent = true, noremap = true, desc = '[Buffer] Previous buffer' })

-- Call vim fugitive
vim.keymap.set('n', '<leader>gg', '<cmd>Git<cr>', {
  noremap = true,
  desc = '[Fugitive] Open fugitive',
})
-- Select blocks after indenting
vim.keymap.set('x', '<', '<gv', {
  noremap = true,
  desc = '[Indent] Reselect indent on decrease',
})
vim.keymap.set('x', '>', '>gv|', {
  noremap = true,
  desc = '[Indent] Reselect indent on increase',
})

-- Use tab for indenting in visual mode
vim.keymap.set('x', '<Tab>', '>gv|', {
  noremap = true,
  desc = '[Indent] Increase indent',
})
vim.keymap.set('x', '<S-Tab>', '<gv', {
  noremap = true,
  desc = '[Indent] Decrease indent',
})
vim.keymap.set('n', '>', '>>_', {
  noremap = true,
  desc = '[Indent] Increase indent',
})
vim.keymap.set('n', '<', '<<_', {
  noremap = true,
  desc = '[Indent] Decrease indent',
})

-- smart up and down
vim.keymap.set('n', '<down>', 'gj', {
  remap = true,
  silent = true,
  desc = '[Nav] Smart down',
})
vim.keymap.set('n', '<up>', 'gk', {
  remap = true,
  silent = true,
  desc = '[Nav] Smart up',
})

-- Configure tab
local function SetTab (space)
  local space_val = tonumber((space == nil or space == '') and '2' or space, 10)
  vim.opt.tabstop = space_val
  vim.opt.softtabstop = space_val
  vim.opt.shiftwidth = space_val
  vim.opt.expandtab = true
  vim.opt.ruler = true
  vim.opt.autoindent = true
  vim.opt.smartindent = true
end

vim.g.SetTab = SetTab
vim.api.nvim_create_user_command('SetTab', SetTab, {})
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Run after all plugins are loaded and nvim is ready',
  pattern = { '*' },
  callback = function ()
    SetTab()
  end,
})

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
vim.keymap.set('x', '<Leader>y', ':<C-u>call clipboard#yank()<cr>', {
  desc = 'Yank selection to system clipboard',
  silent = true,
  noremap = true,
})
vim.keymap.set('n', '<Leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('n', '<Leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<Leader>p', 'clipboard#paste("p")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})
vim.keymap.set('x', '<Leader>P', 'clipboard#paste("P")', {
  desc = 'Paste content of system clipboard after the cursor',
  expr = true,
  noremap = true,
})

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

-- Enable fold method using indent
-- Ref: https://www.reddit.com/r/neovim/comments/10q2mjq/comment/j6nmuw8
-- also consider plugin: https://github.com/kevinhwang91/nvim-ufo
vim.cmd([[execute 'set fillchars=fold:\ ,foldopen:,foldsep:\ ,foldclose:']])
vim.opt.foldmethod = 'indent'
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- ignore case in searches
vim.opt.ignorecase = true
-- Ignore casing unless using uppercase characters
vim.opt.smartcase = true

-- always open on the right
vim.opt.splitright = true
-- always split below
vim.opt.splitbelow = true

-- Set relative numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Make nocompatible explicit
vim.opt.compatible = false
-- Default encoding
vim.opt.encoding = 'UTF-8'
vim.opt.cursorline = true
vim.opt.termguicolors = true

-- enable filetype base indentation
vim.cmd('filetype plugin indent on')
-- Enable highlight on search
vim.opt.hlsearch = true

-- NOTE: Set by VimPlug
-- enable syntax highlight
-- > syntax enabled

-- Set backspace normal behavior
vim.opt.backspace = 'indent,eol,start'
vim.opt.breakindent = true
-- Set hidden on
vim.opt.hidden = true

-- Set workable mouse scroll
-- For selecting text hold shift while selecting text
-- or set mouse=r and then select text in command mode (:)
-- NOTE: This prevents right click paste.
-- use ctrl+shift+v, <leader>p or zp/zP
vim.opt.mouse = 'a'

