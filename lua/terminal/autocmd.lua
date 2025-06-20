local register = function()
  local fugitive_group = vim.api.nvim_create_augroup('fugitive_group', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_group,
    pattern = 'fugitive',
    desc = '[fugitive] Bring back the "a" keymap',
    callback = function(opts)
      vim.keymap.set('n', 'a', function ()
        return '-'
      end,
        {
          silent = true,
          remap = true,
          expr = true,
          desc = '[fugitive] Toggle file staging',
          buffer = opts.buf
        })
    end
  })

  local custom_term = vim.api.nvim_create_augroup('custom_term', { clear = true })
  vim.api.nvim_create_autocmd('TermOpen', {
    group = custom_term,
    desc = '[Terminal] Setup terminal buffer',
    pattern = '*',
    callback = function()
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.bufhidden = 'hide'
      vim.cmd.startinsert()
    end,
  })

  -- Return to last edit position when opening files
  vim.api.nvim_create_autocmd('BufReadPost', {
    desc = 'Recover previous cursor position in buffer',
    pattern = { '*' },
    callback = function()
      if (vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$")) then
        vim.fn.execute("normal! g`\"zz")
      end
    end
  })
end

return {
  register = register,
}
