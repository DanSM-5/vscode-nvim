local buf = vim.api.nvim_get_current_buf()

vim.keymap.set('n', '%', function()
  require('config.netrw').createFile()
end, { buffer = buf, noremap = true, desc = '[netrw] create file' })
vim.keymap.set('n', '<localleader>5', function()
  require('config.netrw').createFile({ edit = true })
end, { buffer = buf, noremap = true, desc = '[netrw] create file (edit)' })
