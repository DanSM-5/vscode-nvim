-- Ref: https://github.com/juniorsundar/nvim/blob/679acb2e259f23a55fc87ba837bab18705cfc3e7/lua/config/lsp/breadcrumbs.lua

local kinds = {
  'File', -- 1
  'Module', -- 2
  'Namespace', -- 3
  'Package', -- 4
  'Class', -- 5
  'Method', -- 6
  'Property', -- 7
  'Field', -- 8
  'Constructor', -- 9
  'Enum', -- 10
  'Interface', -- 11
  'Function', -- 12
  'Variable', -- 13
  'Constant', -- 14
  'String', -- 15
  'Number', -- 16
  'Boolean', -- 17
  'Array', -- 18
  'Object', -- 19
  'Key', -- 20
  'Null', -- 21
  'EnumMember', -- 22
  'Struct', -- 23
  'Event', -- 24
  'Operator', -- 25
  'TypeParameter', -- 26
}

local kind_icons = {
  File = "󰈙",
  Module = "",
  Namespace = "󰅩",
  Package = "",
  Class = "󰠱",
  Method = "󰆧",
  Property = "󰜢",
  Field = "󰇽",
  Constructor = "",
  Enum = "",
  Interface = "",
  Function = "󰊕",
  Variable = "󰂡",
  Constant = "󰏿",
  String = "𝓐",
  Number = "󰎠",
  Boolean = "󰨙",
  Array = "󰅪",
  Object = "󱃖", --  󱃖 
  Key = "",
  Null = "",
  EnumMember = "",
  Struct = "",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰅲",

  Branch = "",
  Color = "󰏘",
  Folder = "󰉋",
  Keyword = "󰌋",
  Reference = "",
  Snippet = "",
  Text = "",
  Unit = "",
  Value = "󰎠",
}

local kind_hl = {
  File = "Title",
  Module = "@module",
  Namespace = "@lsp.type.namespace",
  Package = "@keyword",
  Class = "@lsp.type.class",
  Method = "@lsp.type.method",
  Property = "@property",
  Field = "@property",
  Constructor = "@constructor",
  Enum = "@lsp.type.enum",
  Interface = "@lsp.type.interface",
  Function = "Function", -- @function.method
  Variable = "@variable",
  Constant = "@constant",
  String = "@string",
  Number = "@lsp.type.number",
  Boolean = "@boolean",
  Array = "@variable",
  Object = "Identifier", --  󱃖 
  Key = "@keyword",
  Null = "@comment",
  EnumMember = "@lsp.type.enumMember",
  Struct = "Structure",
  Event = "@lsp.type.event",
  Operator = "@lsp.type.operator",
  TypeParameter = "@lsp.type.type",

  Branch = "@diff.plus",
  Color = "String",
  Folder = "Directory",
  Keyword = "@keyword",
  Reference = "LspReferenceText",
  Snippet = "SnippetTabstop",
  Text = "@string",
  Unit = "Delimiter",
  Value = "@lsp.type.variable",
}

---Get the symbol name
---@param symbol lsp.DocumentSymbol|lsp.SymbolInformation
---@return string name the name of the symbol
local function get_name(symbol)
  local name = vim.trim(symbol.name)
  return (name and name ~= '') and name or '[anon]'
end

local function range_contains_pos(range, line, char)
  local start = range.start
  local stop = range['end']

  if line < start.line or line > stop.line then
    return false
  end

  if line == start.line and char < start.character then
    return false
  end

  if line == stop.line and char > stop.character then
    return false
  end

  return true
end

---@param symbol_list lsp.DocumentSymbol[]|lsp.SymbolInformation[]
---@param line integer
---@param char integer integer position
---@param path string[] accumulated breadcrumbs
local function find_symbol_path(symbol_list, line, char, path)
  if not symbol_list or #symbol_list == 0 then
    return false
  end

  for _, symbol in ipairs(symbol_list) do
    if range_contains_pos(symbol.range, line, char) then
      local kind = kinds[symbol.kind]
      local icon = kind_icons[kind]
      local hl = kind_hl[kind]
      local segment = ('%%#%s#%s %s'):format(hl, icon, get_name(symbol))
      table.insert(path, segment)
      find_symbol_path(symbol.children, line, char, path)
      return true
    end
  end
  return false
end

---@param err lsp.ResponseError
---@param symbols lsp.DocumentSymbol[]|lsp.SymbolInformation[]|nil
---@param ctx lsp.HandlerContext
---@param config table?
local function lsp_callback(err, symbols, ctx, config)
  local file_path = vim.fn.bufname(ctx.bufnr)
  if not file_path or file_path == '' then
    vim.opt_local.winbar = '[No Name]'
    return
  else
    file_path = vim.fs.normalize(file_path)
  end

  local relative_path

  local clients = vim.lsp.get_clients({ bufnr = ctx.bufnr })
  ---@type vim.lsp.Client[]
  local clients_with_root = vim.tbl_filter(function(c) return c.root_dir end, clients)

  -- Use project root as reference if available
  if #clients_with_root > 0 and clients_with_root[1].root_dir then
    local root_dir = clients_with_root[1].root_dir
    if root_dir == nil then
      relative_path = ''
    else
      root_dir = vim.fs.normalize(root_dir)
      relative_path = vim.fs.relpath(root_dir, file_path)
      assert(relative_path, 'No relative path found')
      ---@cast relative_path string

      local parts = vim.split(relative_path, '/', { plain = true, trimempty = true })
      for i, p in ipairs(parts) do
        local icon, hl
        if i == #parts then
          icon, hl = kind_icons.File, kind_hl.File
        else
          icon, hl = kind_icons.Folder, kind_hl.Folder
        end
        parts[i] = ('%%#%s#%s %s'):format(hl, icon, p)
      end

      -- relative_path = string.gsub(relative_path, '/', ' > ')
      relative_path = table.concat(parts, '%#Delimiter#  ')
    end
  else
    -- Use filename only
    relative_path = ('%s %s'):format(kind_icons.File, file_path)
  end

  local breadcrumbs = { relative_path }

  if err or not symbols then
    -- vim.opt_local.winbar = ''
    return
  else
    local pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = pos[1] - 1
    local cursor_char = pos[2]

    find_symbol_path(symbols, cursor_line, cursor_char, breadcrumbs)
  end


  local breadcrumb_string = table.concat(breadcrumbs, '%#Delimiter#  ')

  if breadcrumb_string ~= '' then
    vim.opt_local.winbar = breadcrumb_string
  else
    vim.opt_local.winbar = ' '
  end
end

local function breadcrumbs_set()
  local bufnr = vim.api.nvim_get_current_buf()
  local textDocument = vim.lsp.util.make_text_document_params(bufnr)
  if not textDocument.uri then
    vim.print('Error: Could not get URI for buffer. Is it saved?')
    return
  end

  local params = {
    textDocument = textDocument,
  }
  vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, lsp_callback)
end

local breadcrumbs_augroup = vim.api.nvim_create_augroup('Breadcrumbs', { clear = true })

---@type table<integer, { acid: integer; clients: integer[]; }|nil>
local buffers = {}

---Detach buffer from autocmd
---@param buf integer buffer to detach
local function do_detach(buf)
  buffers[buf] = nil -- remove object reference
  pcall(vim.api.nvim_del_autocmd, buffers[buf].acid)
  vim.opt_local.winbar = '' -- cleanup winbar
  -- pcall(vim.api.nvim_clear_autocmds, {
  --   event = 'CursorMoved',
  --   buffer = buf,
  --   group = breadcrumbs_augroup,
  -- })
end

---Attach buffer to autocmd
---@param buf integer buffer to attach
---@return integer acid id of autocmd
local function do_attach(buf)
  local acid = vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    group = breadcrumbs_augroup,
    callback = breadcrumbs_set,
    desc = '[Breadcrumbs] Set breadcrumbs.',
    buffer = buf,
  })

  return acid
end

local function attach(buf, clientId)
  -- if already attached
  if buffers[buf] then
    table.insert(buffers[buf].clients, clientId)
    return
  end

  local acid = do_attach(buf)
  buffers[buf] = { acid = acid, clients = { clientId } }
end

local function detach(buf, clientId)
  -- nothing to detach
  if not buffers[buf] then
    return
  end

  ---@type integer[]
  local remaining = vim.tbl_filter(function(id)
    return id ~= clientId
  end, buffers[buf].clients)

  -- Still lsps, subtract the client only
  if #remaining > 0 then
    buffers[buf].clients = remaining
  else
    -- No more clients, do detach
    pcall(do_detach, buf)
  end
end

---Stop breadcrumb on buffer
---@param buf? integer buffer to stop breadcrumbs from appearing
local function stop(buf)
  local bufnr = buf or vim.api.nvim_get_current_buf()

  -- nothing to detach
  if not buffers[bufnr] then
    return
  end

  pcall(do_detach, bufnr)
end

---Start breadcrumb on buffer
---@param buf? integer buffer to start showing breadcrumbs
local function start(buf)
  local bufnr = buf or vim.api.nvim_get_current_buf()

  -- if already attached
  if buffers[bufnr] then
    return
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  ---@type integer[]
  local supported = {}
  vim.tbl_map(function(c)
    ---@cast c vim.lsp.Client
    if c:supports_method('textDocument/documentSymbol') then
      table.insert(supported, c.id)
    end

    return c
  end, clients)

  if #supported > 0 then
    local acid = do_attach(bufnr)
    buffers[bufnr] = { acid = acid, clients = supported }
  end
end

-- Helper autocmd to cleanup non-attached buffers
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(opts)
    if not buffers[opts.buf] then
      vim.opt_local.winbar = ''
    end
  end,
  desc = '[Breadcrumbs] Cleanup function on non-attached buffers',
  group = breadcrumbs_augroup,
})

return {
  attach = attach,
  detach = detach,
  stop = stop,
  start = start,
}
