---@alias hierarchy.Direction
---| 'outcoming'
---| 'incoming'

local method = 'textDocument/prepareCallHierarchy'

local Hierarchy = {}

Hierarchy.reference_tree = {}
Hierarchy.pending_items = 0
Hierarchy.depth = 3
Hierarchy.current_item = nil
Hierarchy.refs_buf = nil
Hierarchy.refs_ns = vim.api.nvim_create_namespace('function_references')
Hierarchy.line_data = {}
Hierarchy.expanded_nodes = {}

function Hierarchy.safe_call(fn, ...)
  local status, result = pcall(fn, ...)
  if not status then
    vim.schedule(function()
      vim.notify('Function call error (handled): ' .. tostring(result), vim.log.levels.DEBUG)
    end)
    return nil
  end
  return result
end

---@param item table
---@param parent_node table
local function create_reference_node(item, parent_node)
  --- Check if the item is an exact self-reference
  if
    item.name == parent_node.name
    and item.uri == parent_node.uri
    and item.selectionRange.start.line == parent_node.selectionRange.start.line
  then
    return nil
  end

  -- Return existing node if it exists
  local current_node = parent_node.references[item.name]
  if current_node then
    return current_node
  end

  current_node = {
    name = item.name,
    uri = item.uri,
    range = item.range,
    selectionRange = item.selectionRange,
    references = {},
    display = item.name
      .. ' ['
      .. vim.fn.fnamemodify(item.uri, ':t')
      .. ':'
      .. (item.selectionRange.start.line + 1)
      .. ']',
  }
  parent_node.references[item.name] = current_node

  return current_node
end

---@param client_id integer
local function request_outgoingCalls(item, current_depth, parent_node, client_id)
  local client = vim.lsp.get_clients({ id = client_id })[1]
  if not client then
    vim.notify('Could not get the client from context', vim.log.levels.ERROR)
    return
  end

  ---@type lsp.Handler
  local function handler_outgoingCalls(err, result, ctx)
    ---@cast result lsp.CallHierarchyOutgoingCall[]

    local current_node = nil
    if current_depth > 1 then
      current_node = create_reference_node(item, parent_node)
    end

    if not err and result and not vim.tbl_isempty(result) then
      for _, call in ipairs(result) do
        local target = call.to
        local next_parent = current_node or parent_node

        Hierarchy.pending_items = Hierarchy.pending_items + 1
        vim.defer_fn(function()
          Hierarchy.process_outcoming_item_calls(target, current_depth + 1, next_parent, ctx.client_id)
        end, 0)
      end
    end

    Hierarchy.pending_items = Hierarchy.pending_items - 1

    if Hierarchy.pending_items == 0 then
      Hierarchy.display_custom_ui()
    end
  end

  local params = { item = item }
  client:request('callHierarchy/outgoingCalls', params, handler_outgoingCalls)
end

---@param client_id integer
local function request_incomingCalls(item, current_depth, parent_node, client_id)
  local client = vim.lsp.get_clients({ id = client_id })[1]
  if not client then
    vim.notify('Could not get the client from context', vim.log.levels.ERROR)
    return
  end

  ---@type lsp.Handler
  local handler_incomingCalls = function(err, result, ctx)
    ---@cast result lsp.CallHierarchyIncomingCall[]

    local current_node = nil
    if current_depth > 1 then
      current_node = create_reference_node(item, parent_node)
    end

    if not err and result and not vim.tbl_isempty(result) then
      for _, call in ipairs(result) do
        local target = call.from
        local next_parent = current_node or parent_node

        Hierarchy.pending_items = Hierarchy.pending_items + 1
        vim.defer_fn(function()
          Hierarchy.process_incoming_item_calls(target, current_depth + 1, next_parent, ctx.client_id)
        end, 0)
      end
    end

    Hierarchy.pending_items = Hierarchy.pending_items - 1

    if Hierarchy.pending_items == 0 then
      Hierarchy.display_custom_ui()
    end
  end

  local params = { item = item }
  client:request('callHierarchy/incomingCalls', params, handler_incomingCalls)
end

function Hierarchy.process_item_calls(item, current_depth, parent_node, client_id)
  -- Stop if we've exceeded the maximum depth
  if current_depth > Hierarchy.depth then
    Hierarchy.pending_items = Hierarchy.pending_items - 1
    if Hierarchy.pending_items == 0 then
      Hierarchy.display_custom_ui()
    end
    return
  end

  if not parent_node or type(parent_node) ~= 'table' or not parent_node.references then
    vim.notify('Error: Invalid parent_node in process_item_calls', vim.log.levels.ERROR)
    Hierarchy.pending_items = Hierarchy.pending_items - 1
    if Hierarchy.pending_items == 0 then
      Hierarchy.display_custom_ui()
    end
    return
  end
end

function Hierarchy.process_outcoming_item_calls(item, current_depth, parent_node, client_id)
  Hierarchy.process_item_calls(item, current_depth, parent_node, client_id)
  request_outgoingCalls(item, current_depth, parent_node, client_id)
end

function Hierarchy.process_incoming_item_calls(item, current_depth, parent_node, client_id)
  Hierarchy.process_item_calls(item, current_depth, parent_node, client_id)
  request_incomingCalls(item, current_depth, parent_node, client_id)
end

function Hierarchy.build_reference_lines(node, lines, indent, expanded_nodes)
  indent = indent or 0
  lines = lines or {}
  expanded_nodes = expanded_nodes or {}

  local icon = '󰅲'

  if node.name:match('[Dd]ebug') then
    icon = '⭐'
  end

  local has_refs = node.references and next(node.references) ~= nil

  local prefix = string.rep('  ', indent)
  local expanded = expanded_nodes[node.name .. node.uri]

  if has_refs then
    prefix = prefix .. (expanded and '▼ ' or '▶ ')
  else
    prefix = prefix .. '  '
  end

  local location = ''
  if node.uri then
    location = ' [' .. vim.fn.fnamemodify(node.uri, ':t') .. ':' .. (node.selectionRange.start.line + 1) .. ']'
  end

  table.insert(lines, {
    text = prefix .. icon .. ' ' .. node.name .. location,
    node = node,
    indent = indent,
    has_refs = has_refs,
  })

  if expanded and has_refs then
    for _, child in pairs(node.references) do
      Hierarchy.build_reference_lines(child, lines, indent + 1, expanded_nodes)
    end
  end

  return lines
end

function Hierarchy.display_custom_ui()
  if not Hierarchy.reference_tree or vim.tbl_isempty(Hierarchy.reference_tree.references) then
    vim.notify('No function references found', vim.log.levels.INFO)
    return
  end

  if not Hierarchy.refs_buf or not vim.api.nvim_buf_is_valid(Hierarchy.refs_buf) then
    Hierarchy.refs_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(Hierarchy.refs_buf, 'FunctionReferences')

    local function safe_set_buf_option(buf, name, value)
      pcall(vim.api.nvim_set_option_value, name, value, { buf = buf })
    end

    safe_set_buf_option(Hierarchy.refs_buf, 'buftype', 'nofile')
    safe_set_buf_option(Hierarchy.refs_buf, 'bufhidden', 'hide')
    safe_set_buf_option(Hierarchy.refs_buf, 'swapfile', false)
    safe_set_buf_option(Hierarchy.refs_buf, 'modifiable', false)
    safe_set_buf_option(Hierarchy.refs_buf, 'filetype', 'FunctionReferences')

    vim.api.nvim_create_autocmd('BufWinLeave', {
      buffer = Hierarchy.refs_buf,
      callback = function()
        if Hierarchy.refs_buf and vim.api.nvim_buf_is_valid(Hierarchy.refs_buf) then
          vim.api.nvim_buf_set_var(Hierarchy.refs_buf, 'expanded_nodes', {})
        end
      end,
      once = true,
    })
  else
    vim.api.nvim_set_option_value('modifiable', true, { buf = Hierarchy.refs_buf })
    vim.api.nvim_buf_set_lines(Hierarchy.refs_buf, 0, -1, false, {})
  end

  local expanded_nodes = {}
  if Hierarchy.refs_buf and vim.api.nvim_buf_is_valid(Hierarchy.refs_buf) then
    if vim.api.nvim_buf_is_loaded(Hierarchy.refs_buf) then
      local ok, nodes = pcall(vim.api.nvim_buf_get_var, Hierarchy.refs_buf, 'expanded_nodes')
      if ok then
        expanded_nodes = nodes
      end
    end
  end

  expanded_nodes[Hierarchy.reference_tree.name .. Hierarchy.reference_tree.uri] = true

  local lines = Hierarchy.build_reference_lines(Hierarchy.reference_tree, {}, 0, expanded_nodes)

  local text_lines = {}
  for _, line in ipairs(lines) do
    table.insert(text_lines, line.text)
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = Hierarchy.refs_buf })
  vim.api.nvim_buf_set_lines(Hierarchy.refs_buf, 0, -1, false, text_lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = Hierarchy.refs_buf })

  pcall(vim.api.nvim_buf_set_var, Hierarchy.refs_buf, 'line_data', lines)
  pcall(vim.api.nvim_buf_set_var, Hierarchy.refs_buf, 'expanded_nodes', expanded_nodes)

  Hierarchy.line_data = lines
  Hierarchy.expanded_nodes = expanded_nodes

  vim.api.nvim_buf_clear_namespace(Hierarchy.refs_buf, Hierarchy.refs_ns, 0, -1)
  for i, line in ipairs(lines) do
    local icon_start = line.text:find('󰅲') or line.text:find('⭐')
    if icon_start then
      vim.hl.range(Hierarchy.refs_buf, Hierarchy.refs_ns, 'Special', { i - 1, icon_start - 1 }, { i - 1, icon_start })
    end

    local name_start = line.text:find(line.node.name)
    if name_start then
      vim.hl.range(
        Hierarchy.refs_buf,
        Hierarchy.refs_ns,
        'Function',
        { i - 1, name_start - 1 },
        { i - 1, name_start + #line.node.name - 1 }
      )
    end

    local loc_start = line.text:find(' %[')
    if loc_start then
      vim.hl.range(Hierarchy.refs_buf, Hierarchy.refs_ns, 'Comment', { i - 1, loc_start - 1 }, { i - 1, -1 })
    end
  end

  ---@type vim.keymap.set.Opts
  local keymap_opts = { noremap = true, silent = true, buffer = Hierarchy.refs_buf }
  vim.keymap.set('n', '<CR>', function ()
    Hierarchy.toggle_reference_node()
  end, keymap_opts)

  vim.keymap.set('n', '<2-LeftMouse>', function ()
    Hierarchy.toggle_reference_node()
  end, keymap_opts)

  vim.keymap.set('n', 'gd', function ()
    Hierarchy.goto_function_definition()
  end, keymap_opts)

  local win_width = math.floor(vim.api.nvim_get_option_value('columns', {}) * 0.4)

  local win_id = nil
  for _, wid in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(wid)
    if buf == Hierarchy.refs_buf then
      win_id = wid
      break
    end
  end

  if not win_id then
    vim.cmd('vsplit')
    win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_id, Hierarchy.refs_buf)
    vim.api.nvim_win_set_width(win_id, win_width)
  end

  local function safe_set_win_option(win, name, value)
    pcall(vim.api.nvim_set_option_value, name, value, { win = win })
  end

  safe_set_win_option(win_id, 'wrap', false)
  safe_set_win_option(win_id, 'number', false)
  safe_set_win_option(win_id, 'relativenumber', false)
  safe_set_win_option(win_id, 'signcolumn', 'no')

  vim.api.nvim_set_option_value('filetype', 'FunctionReferences', { buf = Hierarchy.refs_buf })

  pcall(function()
    vim.cmd('setlocal statusline=REFERENCES:\\ ' .. Hierarchy.reference_tree.name:gsub('\\', '\\\\'):gsub(' ', '\\ '))
  end)

  vim.api.nvim_win_set_cursor(win_id, { 1, 0 })
end

function Hierarchy.toggle_reference_node()
  local bufnr = vim.api.nvim_get_current_buf()
  if bufnr ~= Hierarchy.refs_buf then
    return
  end

  local line_nr = vim.api.nvim_win_get_cursor(0)[1]

  local line_data
  local ok, buf_line_data = pcall(vim.api.nvim_buf_get_var, bufnr, 'line_data')
  if ok and buf_line_data and buf_line_data[line_nr] then
    line_data = buf_line_data
  else
    line_data = Hierarchy.line_data
  end

  if not line_data or not line_data[line_nr] then
    return
  end

  local item = line_data[line_nr]
  if not item.has_refs then
    Hierarchy.goto_function_definition()
    return
  end

  local expanded_nodes
  local ok2, buf_expanded_nodes = pcall(vim.api.nvim_buf_get_var, bufnr, 'expanded_nodes')
  if ok2 and buf_expanded_nodes then
    expanded_nodes = buf_expanded_nodes
  else
    expanded_nodes = Hierarchy.expanded_nodes or {}
  end

  local node_id = item.node.name .. item.node.uri
  expanded_nodes[node_id] = not expanded_nodes[node_id]

  pcall(vim.api.nvim_buf_set_var, bufnr, 'expanded_nodes', expanded_nodes)
  Hierarchy.expanded_nodes = expanded_nodes

  Hierarchy.redraw_references_buffer()

  vim.api.nvim_win_set_cursor(0, { line_nr, 0 })
end

function Hierarchy.redraw_references_buffer()
  if not Hierarchy.refs_buf or not vim.api.nvim_buf_is_valid(Hierarchy.refs_buf) then
    return
  end

  local expanded_nodes
  local ok, buf_expanded_nodes = pcall(vim.api.nvim_buf_get_var, Hierarchy.refs_buf, 'expanded_nodes')
  if ok and buf_expanded_nodes then
    expanded_nodes = buf_expanded_nodes
  else
    expanded_nodes = Hierarchy.expanded_nodes or {}
  end

  local lines = Hierarchy.build_reference_lines(Hierarchy.reference_tree, {}, 0, expanded_nodes)

  local text_lines = {}
  for _, line in ipairs(lines) do
    table.insert(text_lines, line.text)
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = Hierarchy.refs_buf })
  vim.api.nvim_buf_set_lines(Hierarchy.refs_buf, 0, -1, false, text_lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = Hierarchy.refs_buf })

  pcall(vim.api.nvim_buf_set_var, Hierarchy.refs_buf, 'line_data', lines)
  Hierarchy.line_data = lines

  vim.api.nvim_buf_clear_namespace(Hierarchy.refs_buf, Hierarchy.refs_ns, 0, -1)
  for i, line in ipairs(lines) do
    local icon_start = line.text:find("󰅲") or line.text:find("⭐")
    if icon_start then
      vim.hl.range(Hierarchy.refs_buf, Hierarchy.refs_ns, 'Special', { i - 1, icon_start - 1 }, { i - 1, icon_start })
    end

    local name_start = line.text:find(line.node.name)
    if name_start then
      vim.hl.range(
        Hierarchy.refs_buf,
        Hierarchy.refs_ns,
        'Function',
        { i - 1, name_start - 1 },
        { i - 1, name_start + #line.node.name - 1 }
      )
    end

    local loc_start = line.text:find(' %[')
    if loc_start then
      vim.hl.range(Hierarchy.refs_buf, Hierarchy.refs_ns, 'Comment', { i - 1, loc_start - 1 }, { i - 1, -1 })
    end
  end
end

function Hierarchy.goto_function_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  if bufnr ~= Hierarchy.refs_buf then
    return
  end

  local line_nr = vim.api.nvim_win_get_cursor(0)[1]

  local line_data
  local ok, buf_line_data = pcall(vim.api.nvim_buf_get_var, bufnr, 'line_data')
  if ok and buf_line_data and buf_line_data[line_nr] then
    line_data = buf_line_data
  else
    line_data = Hierarchy.line_data
  end

  if not line_data or not line_data[line_nr] then
    return
  end

  local item = line_data[line_nr]
  local node = item.node

  if node and node.uri and node.selectionRange then
    local filename = vim.uri_to_fname(node.uri)

    local jump_cmd = 'edit +' .. (node.selectionRange.start.line + 1) .. ' ' .. vim.fn.fnameescape(filename)

    vim.cmd(jump_cmd)

    if node.selectionRange.start.character then
      vim.api.nvim_win_set_cursor(0, { node.selectionRange.start.line + 1, node.selectionRange.start.character })
    end
  end
end

---@param direction hierarchy.Direction Direction to search inwards or outwards
---@param depth? integer How deep to search in the calls
---@param lsp_client? vim.lsp.Client Optional client instance to use
function Hierarchy.find_recursive_calls(direction, depth, lsp_client)
  Hierarchy.reference_tree = {
    name = '',
    uri = '',
    range = {},
    selectionRange = {},
    references = {},
    display = '',
  }
  Hierarchy.pending_items = 0
  Hierarchy.depth = depth or 3

  local client = lsp_client or vim.lsp.get_clients({ method = method })[1]
  if not client then
    vim.notify('No LSP client found for call hierarchy', vim.log.levels.ERROR)
    return
  end

  ---@type lsp.Handler
  local handler_prepareCallHierarchy = function(err, result, ctx)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify('Could not prepare call hierarchy', vim.log.levels.ERROR)
      return
    end

    local item = result[1]
    Hierarchy.current_item = item

    Hierarchy.reference_tree = {
      name = item.name,
      uri = item.uri,
      range = item.range,
      selectionRange = item.selectionRange,
      references = {},
      display = item.name
        .. ' ['
        .. vim.fn.fnamemodify(item.uri, ':t')
        .. ':'
        .. (item.selectionRange.start.line + 1)
        .. ']',
      expanded = false,
    }

    Hierarchy.pending_items = 1
    vim.defer_fn(function()
      if direction == 'outcoming' then
        Hierarchy.process_outcoming_item_calls(item, 1, Hierarchy.reference_tree, ctx.client_id)
      elseif direction == 'incoming' then
        Hierarchy.process_incoming_item_calls(item, 1, Hierarchy.reference_tree, ctx.client_id)
      else
        vim.notify("Invalid direction specified. Use 'incoming' or 'outcoming'.", vim.log.levels.ERROR)
      end
    end, 0)
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request(method, params, handler_prepareCallHierarchy)
end

return Hierarchy
