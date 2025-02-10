-- Set colorscheme
vim.cmd.colorscheme('slate')

-- Mappings to help navigation
vim.keymap.set('n', '<c-p>', ':<C-u>GFiles<cr>', {
  noremap = true,
  desc = '[Fzf] Git files',
})

