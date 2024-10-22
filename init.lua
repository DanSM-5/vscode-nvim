-- IMPORTANT Settings
-- Location for the vscode-nvim config
vim.g.config_dir = vim.fn.expand('~/.config/vscode-nvim')

-- Add config dir to runtimepath
vim.opt.runtimepath:prepend(vim.g.config_dir)
-- Remove common nvim config location
vim.opt.runtimepath:remove(vim.fn.expand('~/.config/nvim'))
vim.opt.runtimepath:remove(vim.fn.expand('~/AppData/Local/nvim'))
vim.cmd('set runtimepath^=' .. vim.g.config_dir)
vim.cmd('set runtimepath-=' .. vim.fn.expand('~/AppData/Local/nvim'))

-- NOTE: Lazy is messing up with the rtp and it forces default path location.
-- requiring this modules here to avoid cache issues
require('utils.repeat_motion')
require('keymaps')

require('vimstart')
require('platform_setup')
require('config.lazy')
-- NOTE: Lazy adds the default directory again after loading 🙃
vim.cmd('set runtimepath^=' .. vim.g.config_dir)
vim.cmd('set runtimepath-=' .. vim.fn.expand('~/AppData/Local/nvim'))
require('vscode_config')
require('keymaps').set_defualt()

