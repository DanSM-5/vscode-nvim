local exclude_filetypes = {
  'help',
  'fzf',
  'fugitive',
  'qf',
}

local nxo = { 'n', 'x', 'o' }
local first_refjump_call = false

---Get the function for on_forward and on_backward
---@param forward boolean If to move forward or backward
---@param client_id integer Id of the lsp client
local ref_jump = function(forward, client_id)
  ---References cache
  ---@type RefjumpReference[]?
  local references
  local refjump = require('lib.refjump')
  if first_refjump_call == false then
    first_refjump_call = true
    refjump.start_hl()
  end

  -- NOTE: It is important to make only this part repeatable and not the whole keymap
  -- so that references will be a brand new reference variable but
  -- it will have the cached references if repeating the motion
  require('utils.repeat_motion').repeat_direction({
    fn = function(opts)
      refjump.reference_jump(opts, references, client_id, function(refs)
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

    pcall(vim.keymap.set, mode, key, func, opts)
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
  set_map('n', 'gD', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.declaration_call()
      return
    end

    -- fallback
    vim.lsp.buf.declaration()
  end, '[Lsp]: Go to declaration')
  set_map('n', 'gd', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.definition_call()
      return
    end

    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition')
  set_map('n', '<space>ds', function()
    vim.cmd.split()

    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.definition_call()
      return
    end

    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', '<space>dv', function()
    vim.cmd.vsplit()

    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.definition_call()
      return
    end

    vim.lsp.buf.definition()
  end, '[Lsp]: Go to definition in vsplit')
  set_map('n', 'K', function()
    vim.lsp.buf.hover({ border = 'rounded' })
  end, '[Lsp]: Hover action')
  set_map('n', '<space>i', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.implementation_call()
      return
    end

    vim.lsp.buf.implementation()
  end, '[Lsp]: Go to implementation')
  set_map('n', '<C-k>', function()
    vim.lsp.buf.signature_help({ border = 'rounded' })
  end, '[Lsp]: Show signature help')
  set_map('n', '<space>wa', vim.lsp.buf.add_workspace_folder, '[Lsp]: Add workspace')
  set_map('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, '[Lsp]: Remove workspace')
  set_map('n', '<space>wl', function()
    vim.print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[Lsp]: List workspaces')
  set_map('n', '<space>D', function ()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.type_definition_call()
      return
    end
    vim.lsp.buf.type_definition()
  end, '[Lsp]: Go to type definition')
  set_map('n', '<space>rn', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<f2>', vim.lsp.buf.rename, '[Lsp]: Rename symbol')
  set_map('n', '<space>ca', function ()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.code_action_call()
      return
    end

    vim.lsp.buf.code_action()
  end, '[Lsp]: Code Actions')
  set_map('n', 'gr', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.references_call()
      return
    end

    vim.lsp.buf.references()
  end, '[Lsp]: Go to references')
  set_map('n', '<space>f', function()
    vim.lsp.buf.format({ async = false })

    -- If we ever need it but hope we don't 🫠
    if vim.env.VIM_DONT_RETAB ~= nil then
      return
    end

    vim.cmd.retab()
    vim.cmd.write()
  end, '[Lsp]: Format buffer')
  set_map('n', '<space>ci', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.incoming_calls_call()
      return
    end

    vim.lsp.buf.incoming_calls()
  end, '[Lsp]: Incoming Calls')
  set_map('n', '<space>co', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.outgoing_calls_call()
      return
    end

    vim.lsp.buf.outgoing_calls()
  end, '[Lsp]: Outgoing Calls')
  set_map('n', '<space>sw', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.workspace_symbol_call({ query = '' })
      return
    end

    vim.lsp.buf.workspace_symbol('')
  end, '[Lsp] Open workspace symbols')
  set_map('n', '<space>sW', function()
    local query = vim.fn.expand('<cword>')
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.workspace_symbol_call({ query = query })
      return
    end

    vim.lsp.buf.workspace_symbol(query)
  end, '[Lsp] Open workspace symbols')
  set_map('n', '<space>sd', function()
    local ok, fzflsp = pcall(require, 'fzf_lsp')
    if ok then
      fzflsp.document_symbol_call()
      return
    end

    vim.lsp.buf.document_symbol({})
  end, '[Lsp] Open document symbols')
  set_map('n', 'gO', function()
    -- preserving default
    vim.lsp.buf.document_symbol({})
  end, '[Lsp] Open document symbols')

  if client:supports_method('textDocument/prepareCallHierarchy') then
    set_map({ 'n', 'x' }, '<space>cs', function()
      local hierarchy = require('lib.hierarchy')
      hierarchy.find_recursive_calls('outcoming', hierarchy.depth, client)
    end, '[Hierarchy] Open [outcoming] call hierarchy of function under cursor')
    set_map({ 'n', 'x' }, '<space>cS', function()
      local hierarchy = require('lib.hierarchy')
      hierarchy.find_recursive_calls('incoming', hierarchy.depth, client)
    end, '[Hierarchy] Open [incoming] call hierarchy of function under cursor')
  end

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
