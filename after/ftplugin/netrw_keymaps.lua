local buf = vim.api.nvim_get_current_buf()

vim.keymap.set('n', '%', function ()
  vim.ui.input({ prompt = 'Enter filename: ' }, function(input)
    local from_win = vim.g.custom_netrw_from_win
    if not input or not from_win or not vim.api.nvim_win_is_valid(from_win) then
      return
    end

    local dir = vim.fs.normalize(vim.fn.expand('%'):gsub('NetrwTreeListing', ''), {})

    if vim.fn.isdirectory(dir) == 0 then
      return
    end

    vim.cmd.Lex({ bang = true })
    vim.cmd.edit(vim.fs.joinpath(dir, input))
  end)
end, { buffer = buf, noremap = true, desc = '[netrw] create file' })
