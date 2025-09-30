-- Show yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('TextYankedGroup', { clear = true }),
  callback = function ()
    vim.highlight.on_yank({ higroup = 'HighlightYankedText' })
  end,
  desc = 'Highlight yanked text',
})
