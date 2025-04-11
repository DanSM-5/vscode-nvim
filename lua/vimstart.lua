-- vim:fileencoding=utf-8:foldmethod=marker

-- Config for neovim in vscode extension
-- Running in vscode can be identified by checking the existance of the
-- variable vim.g.vscode or exists(g:vscode)

-- NOTE: Old shada config. No longer relevant.
-- Change location of shada files for VSCode to avoid conflicts
-- with nvim profile in terminal
-- vim.cmd("set shada+='1000,n$HOME/.cache/vscode-nvim/main.shada")

-- Make nocompatible explisit
vim.cmd('set nocompatible')
-- Default encoding
vim.cmd('set encoding=UTF-8')
-- show line under the cursor
vim.cmd('set cursorline')
-- show numbers
vim.cmd('set number relativenumber')
-- ignore case in search
vim.cmd('set ignorecase')
-- set smart case
vim.cmd('set smartcase')

--: Global variables {{{ :-------------------------------------------------
-- Location for vimplug
-- vim.g.plug_home = vim.g.config_dir .. '/plugged'
-- Camel case motion keybindings
vim.g.camelcasemotion_key = '<leader>'
-- Vim-Asterisk keep cursor position under current letter with
vim.g['asterisk#keeppos'] = 1
-- Prevent smoothie default mappings
vim.g.smoothie_no_default_mappings = 1
-- Prevent open dialog
vim.g.system_copy_silent = 1
--: }}} :------------------------------------------------------------------

-- Vimscript specific
vim.cmd([[
  command! -nargs=1 NXOnoremap nnoremap <args><Bar>xnoremap <args><Bar>onoremap <args>

  " Make search consistent
  NXOnoremap <expr>n (v:searchforward ? 'n' : 'N').'zv'
  NXOnoremap <expr>N (v:searchforward ? 'N' : 'n').'zv'
]])

OnVimEnter = function ()
  -- Border highlight on floats
  vim.api.nvim_set_hl(0, 'FloatBorder', {
    ctermbg = 239,
    ctermfg=144,
    bg = '#4a4a4a',
    fg = '#afaf87',
    force = true,
  })
end

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Run after all plugins are loaded and nvim is ready',
  pattern = { '*' },
  callback = OnVimEnter
})

-- Fix cursor shape on exit
-- Windows version of neovim won't set back the cursor shape
vim.api.nvim_create_autocmd('VimLeave', {
  group = vim.api.nvim_create_augroup('RestoreCursorShapeOnExit', { clear = true }),
  pattern = '*',
  callback = function ()
    vim.opt.guicursor = 'a:ver100-blinkon100'
  end,
})

if vim.fn.has('nvim-0.11.0') == 1 then
  -- Unset defaults and let lsp-settings/keymaps.lua handle the keys
  vim.keymap.del('n', 'grr')
  vim.keymap.del('n', 'grn')
  vim.keymap.del('n', 'gra')
  vim.keymap.del('x', 'gra')
  vim.keymap.del('n', 'gri')
  vim.keymap.del('n', 'gO')
end

-- Enable diagnostics. From nvim-11 is false by default.
vim.diagnostic.enable(true)
