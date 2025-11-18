local vscode = require('vscode')

vim.notify = vscode.notify
vim.g.clipboard = vim.g.vscode_clipboard

-- Highlight when yanking text
vim.api.nvim_set_hl(0, 'HighlightYankedText', {
  bg = '#314963',
  ctermbg = 17,
  force = true,
})

-- VSCode Setup
local keymaps = require('vsc.keymaps')
keymaps.set_default()
keymaps.set_repeatable()
-- If text-objects like af/if, ac/ic, etc. stop working
-- on vscode sometimes it is needed to "force" the detection of
-- the ts query by using a motion ]m/[m. etc.
-- keymaps.treesiter()
require('vsc.commands')
require('vsc.autocmd')

