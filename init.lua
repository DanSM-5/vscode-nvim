-- Change name of application to 'vscode-nvim'
-- so configuration directories use it instead of 'nvim'
-- `:h stdpath`
vim.env.NVIM_APPNAME = 'vscode-nvim'

-- Variables that affect environment
-- $XDG_CONFIG_HOME
-- $XDG_DATA_HOME
-- $XDG_RUNTIME_DIR
-- $XDG_STATE_HOME
-- $XDG_CACHE_HOME
-- $XDG_CONFIG_DIRS

-- TODO: Consider configuring windows locations
-- if vim.env.IS_WINSHELL == 'true' then
  -- vim.env.XDG_CONFIG_HOME = vim.fn.expand('~/.config')
  -- vim.env.XDG_DATA_HOME = vim.fn.expand('~/.local/share')
  -- vim.env.XDG_RUNTIME_DIR
  -- vim.env.XDG_STATE_HOME = vim.fn.expand('~/.local/share')
  -- vim.env.XDG_CACHE_HOME
  -- vim.env.XDG_CONFIG_DIRS
-- end

-- Set config directory
vim.g.config_dir = vim.fn.expand('~/.config/vscode-nvim')

-- Add config dir to runtimepath
vim.opt.runtimepath:prepend(vim.g.config_dir)
local linux_default_config_path = vim.fn.expand('~/.config/nvim')
local windows_default_config_path = vim.fn.expand('~/AppData/Local/nvim')
-- Remove common nvim config location
vim.opt.runtimepath:remove(linux_default_config_path)
vim.opt.runtimepath:remove(windows_default_config_path)
-- Vimscript version
vim.cmd('set runtimepath-=' .. linux_default_config_path)
vim.cmd('set runtimepath-=' .. windows_default_config_path)

-- Leader keys
vim.g.mapleader = '\\'
vim.g.maplocalleader = ' '

require('vimstart')
require('platform_setup')
require('config.lazy')

-- If loading in regular nvim
if not vim.g.vscode then
  return
end

-- Requires running in actual vscode
require('vscode_config')

