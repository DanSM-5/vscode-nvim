local vscode = require('vscode')

vim.notify = vscode.notify
vim.g.clipboard = vim.g.vscode_clipboard

-- VSCode Setup
local keymaps = require('vsc.keymaps')
keymaps.set_default()
keymaps.set_repeatable()
require('vsc.commands')

