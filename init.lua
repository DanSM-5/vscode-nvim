-- IMPORTANT Settings
-- Location for the vscode-nvim config
vim.g.config_dir = vim.fn.expand('~/.config/vscode-nvim')

-- Add config dir to runtimepath
vim.opt.runtimepath:prepend(vim.g.config_dir)
-- Remove common nvim config location
vim.opt.runtimepath:remove(vim.fn.expand('~/.config/nvim'))

require('vimstart')
require('keymaps')
require('platform_setup')
require('config.lazy')
