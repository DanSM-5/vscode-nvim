
-- FIX: Treesitter failing to detect parser for textobjects
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('Treesitter.Buf.Enter', { clear = true }),
  callback = vim.schedule_wrap(function()
    pcall(function() vim.treesitter.get_parser():parse() end)
  end)
})

