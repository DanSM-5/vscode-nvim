local vscode = require('vscode')

vim.notify = vscode.notify
vim.g.clipboard = vim.g.vscode_clipboard

-- VSCode Setup
require('keymaps').set_default()
require('keymaps').set_repeatable()
require('commands')

