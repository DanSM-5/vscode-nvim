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


  -- Change cursor color when recording a macro as a visual help
  local record_group = vim.api.nvim_create_augroup('CursorColorOnRecord', { clear = true })
  local recover_cursor_color = vim.api.nvim_get_hl(0, { name = 'Cursor' })
  vim.api.nvim_create_autocmd('RecordingEnter', {
    desc = 'Change cursor color when recording macro starts',
    group = record_group,
    callback = function ()
      recover_cursor_color = vim.api.nvim_get_hl(0, { name = 'Cursor' })
      -- Set cursor to green to signal that recording started
      vim.api.nvim_set_hl(0, 'Cursor', { fg = '#282c34', bg = '#c678dd', ctermfg = 0, ctermbg = 040 })
    end
  })
  vim.api.nvim_create_autocmd('RecordingLeave', {
    desc = 'Recover cursor color when recording macro starts',
    group = record_group,
    callback = function ()
      if recover_cursor_color == nil or type(recover_cursor_color) ~= 'table' then
        return
      end

      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_set_hl(0, 'Cursor', recover_cursor_color)
    end
  })


  -- Allow to paste from registers in fzf buffer in normal mode
  -- similar to ctrl-r in inser-mode
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'fzf',
    group = vim.api.nvim_create_augroup('PasteFzfBuffer', { clear = true }),
    callback = function (opts)
      vim.keymap.set('n', '<leader>"', function()
        vim.cmd('let @" = getreg(nr2char(getchar()))')
        return 'p'
      end, { buffer = opts.buf, desc = '[fzf] paste register on fzf buffer', noremap = true, expr = true })
      vim.keymap.set('n', '<leader>c', function()
        vim.cmd('let @" = getreg(nr2char(34))')
        return 'p'
      end, { buffer = opts.buf, desc = '[fzf] paste on fzf buffer', noremap = true, expr = true })
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function (opts)
      local id = opts.data.client_id
      local client = vim.lsp.get_client_by_id(id)

      -- early return
      if not client then
        return
      end

      if client:supports_method('textDocument/documentSymbol') then
        pcall(require('lib.breadcrumbs').attach, opts.buf, id)
      end
    end,
    desc = '[Lsp] Generic lsp attach logic',
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    callback = function(opts)
      local id = opts.data.client_id
      pcall(require('lib.breadcrumbs').detach, opts.buf, id)
    end,
    desc = '[Lsp] Generic lsp detach logic',
  })
end

return {
  register = register,
}
