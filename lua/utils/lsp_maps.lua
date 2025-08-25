local exclude_filetypes = {
  'help',
  'fzf',
  'fugitive',
  'qf',
}

local nxo = { 'n', 'x', 'o' }

---Get the function for on_forward and on_backward
---@param forward boolean If to move forward or backward
---@param client_id integer Id of the lsp client
local ref_jump = function(forward, client_id)
  ---References cache
  ---@type RefjumpReference[]?
  local references

  -- NOTE: It is important to make only this part repeatable and not the whole keymap
  -- so that references will be a brand new reference variable but
  -- it will have the cached references if repeating the motion
  require('utils.repeat_motion').repeat_direction({
    fn = function(opts)
      require('lib.refjump').reference_jump(opts, references, client_id, function(refs)
        references = refs
      end)
    end,
  })({ forward = forward })
end

---Setup keymaps for lsp
---@param client vim.lsp.Client
---@param bufnr number
local set_lsp_keys = function(client, bufnr)
  local buf = bufnr

  if
      vim.tbl_contains(exclude_filetypes, vim.bo[buf].buftype)
      or vim.tbl_contains(exclude_filetypes, vim.bo[buf].filetype)
  then
    vim.notify(string.format('[lsp] buffer %s not allowed to attach keymaps', buf))
    return
  end

  -- For debugging
  -- vim.notify('[lsp][attached] Client: '..client.name..' id: '..client.id, vim.log.levels.DEBUG)

  -- Enable completion triggered by <C-x><C-o>
  -- Should now be set by default. Set anyways.
  vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

  -- Wrapper for setting maps with description
  ---Set keymap
  ---@param mode string|table
  ---@param key string
  ---@param func string|fun()
  ---@param desc string
  local set_map = function(mode, key, func, desc)
    local opts = { buffer = buf, silent = true, noremap = true }

    if desc then
      opts.desc = desc
    end

    vim.keymap.set(mode, key, func, opts)
  end

  set_map('n', '<space>td', function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, '[Lsp]: Toggle diagnostics')
  set_map('n', '<space>ti', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ nil }))
  end, '[Lsp]: Toggle inlay hints')
  set_map('n', '<space>tt', function()
    local config = type(vim.diagnostic.config().virtual_text) == 'boolean' and { current_line = true } or true
    vim.diagnostic.config({ virtual_text = config })
  end, '[Lsp]: Toggle virtual text diagnostics current line only')
  set_map('n', '<space>tl', function()
    local config = type(vim.diagnostic.config().virtual_lines) == 'boolean' and { current_line = true } or false
    vim.diagnostic.config({ virtual_lines = config })
  end, '[Lsp]: Toggle virtual lines diagnostics show current line')
  -- Buffer local mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  set_map('n', 'gD', vim.lsp.buf.declaration, '[Lsp]: Go to declaration')
  set_map('n', 'gd', vim.lsp.buf.definition, '[Lsp]: Go to definition')
  set_map('n', '<space>ds', function()
    vim.cmd.split()
    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', '<space>dv', function()
    vim.cmd.vsplit()
    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', 'K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, '[Lsp]: Hover action')
  set_map('n', '<space>i', vim.lsp.buf.implementation, '[Lsp]: Go to implementation')
  set_map('n', '<C-k>', function()
    vim.lsp.buf.signature_help({ border = 'rounded' })
  end, '[Lsp]: Show signature help')
  set_map('n', '<space>wa', vim.lsp.buf.add_workspace_folder, '[Lsp]: Add workspace')
  set_map('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, '[Lsp]: Remove workspace')
  set_map('n', '<space>wl', function()
    vim.print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[Lsp]: List workspaces')
  set_map('n', '<space>D', vim.lsp.buf.type_definition, '[Lsp]: Go to type definition')
  set_map('n', '<space>rn', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<f2>', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<space>ca', vim.lsp.buf.code_action, '[Lsp]: Code Actions')
  set_map('n', 'gr', vim.lsp.buf.references, '[Lsp]: Go to references')
  set_map('n', '<space>f', function()
    vim.lsp.buf.format({ async = false })

    -- If we ever need it but hope we don't 🫠
    if vim.env.VIM_DONT_RETAB ~= nil then
      return
    end

    vim.cmd.retab()
    vim.cmd.write()
  end, '[Lsp]: Format buffer')
  set_map('n', '<space>ci', vim.lsp.buf.incoming_calls, '[Lsp]: Incoming Calls')
  set_map('n', '<space>co', vim.lsp.buf.outgoing_calls, '[Lsp]: Outgoing Calls')

  set_map('n', '<space>sw', function()
    vim.lsp.buf.workspace_symbol('')
  end, '[Lsp] Open workspace symbols')
  set_map('n', '<space>sW', function()
    vim.lsp.buf.workspace_symbol(vim.fn.expand('<cword>'))
  end, '[Lsp] Open workspace symbols')
  set_map('n', '<space>sd', function()
    vim.lsp.buf.document_symbol({})
  end, '[Lsp] Open document symbols')
  set_map('n', 'gO', function()
    vim.lsp.buf.document_symbol({})
  end, '[Lsp] Open document symbols')

  if client:supports_method('textDocument/documentHighlight', buf) then
    set_map(nxo, ']r', function()
      ref_jump(true, client.id)
    end, '[Reference] Next reference')
    set_map(nxo, '[r', function()
      ref_jump(false, client.id)
    end, '[Reference] Next reference')
  end
end

return {
  set_lsp_keys = set_lsp_keys,
}
