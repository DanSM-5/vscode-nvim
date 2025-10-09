---@module 'lib.treesitter.lsp_interop'

local EMPTY_ITER = function() end

local utils = {}

--- TSRange

local TSRange = {}
TSRange.__index = TSRange

local api = vim.api

local function get_byte_offset(buf, row, col)
  return api.nvim_buf_get_offset(buf, row) + vim.fn.byteidx(api.nvim_buf_get_lines(buf, row, row + 1, false)[1], col)
end

function TSRange.new(buf, start_row, start_col, end_row, end_col)
  return setmetatable({
    start_pos = { start_row, start_col, get_byte_offset(buf, start_row, start_col) },
    end_pos = { end_row, end_col, get_byte_offset(buf, end_row, end_col) },
    buf = buf,
    [1] = start_row,
    [2] = start_col,
    [3] = end_row,
    [4] = end_col,
  }, TSRange)
end

function TSRange.from_nodes(buf, start_node, end_node)
  TSRange.__index = TSRange
  local start_pos = start_node and { start_node:start() } or { end_node:start() }
  local end_pos = end_node and { end_node:end_() } or { start_node:end_() }
  return setmetatable({
    start_pos = { start_pos[1], start_pos[2], start_pos[3] },
    end_pos = { end_pos[1], end_pos[2], end_pos[3] },
    buf = buf,
    [1] = start_pos[1],
    [2] = start_pos[2],
    [3] = end_pos[1],
    [4] = end_pos[2],
  }, TSRange)
end

function TSRange.from_table(buf, range)
  return setmetatable({
    start_pos = { range[1], range[2], get_byte_offset(buf, range[1], range[2]) },
    end_pos = { range[3], range[4], get_byte_offset(buf, range[3], range[4]) },
    buf = buf,
    [1] = range[1],
    [2] = range[2],
    [3] = range[3],
    [4] = range[4],
  }, TSRange)
end

function TSRange:parent()
  local root_lang_tree = utils.get_parser(self.buf)
  local root = utils.get_root_for_position(self[1], self[2], root_lang_tree)

  return root
      and root:named_descendant_for_range(self.start_pos[1], self.start_pos[2], self.end_pos[1], self.end_pos[2])
    or nil
end

function TSRange:field() end

function TSRange:child_count()
  return #self:collect_children()
end

function TSRange:named_child_count()
  return #self:collect_children(function(c)
    return c:named()
  end)
end

function TSRange:iter_children()
  local raw_iterator = self:parent().iter_children()
  return function()
    while true do
      local node = raw_iterator()
      if not node then
        return
      end
      local _, _, start_byte = node:start()
      local _, _, end_byte = node:end_()
      if start_byte >= self.start_pos[3] and end_byte <= self.end_pos[3] then
        return node
      end
    end
  end
end

function TSRange:collect_children(filter_fun)
  local children = {}
  for _, c in self:iter_children() do
    if not filter_fun or filter_fun(c) then
      table.insert(children, c)
    end
  end
  return children
end

function TSRange:child(index)
  return self:collect_children()[index + 1]
end

function TSRange:named_child(index)
  return self:collect_children(function(c)
    return c.named()
  end)[index + 1]
end

function TSRange:start()
  return unpack(self.start_pos)
end

function TSRange:end_()
  return unpack(self.end_pos)
end

function TSRange:range()
  return self.start_pos[1], self.start_pos[2], self.end_pos[1], self.end_pos[2]
end

function TSRange:type()
  return 'nvim-treesitter-range'
end

function TSRange:symbol()
  return -1
end

function TSRange:named()
  return false
end

function TSRange:missing()
  return false
end

function TSRange:has_error()
  return #self:collect_children(function(c)
    return c:has_error()
  end) > 0 and true or false
end

function TSRange:sexpr()
  return table.concat(
    vim.tbl_map(function(c)
      return c:sexpr()
    end, self:collect_children()),
    ' '
  )
end

--- TSRange end

local mt = {}
mt.__index = function(tbl, key)
  if rawget(tbl, key) == nil then
    rawset(tbl, key, {})
  end
  return rawget(tbl, key)
end

---@type table<string, table<string, boolean>>
local query_files_cache = {}

utils.built_in_query_groups = { 'highlights', 'locals', 'folds', 'indents', 'injections' }

-- Creates a function that checks whether a given query exists
-- for a specific language.
---@param query string
---@return fun(string): boolean
local function get_query_guard(query)
  return function(lang)
    return utils.has_query_files(lang, query)
  end
end

for _, query in ipairs(utils.built_in_query_groups) do
  utils['has_' .. query] = get_query_guard(query)
end

---@param lang string
---@param query_name string
---@return string[]
local function runtime_queries(lang, query_name)
  return vim.api.nvim_get_runtime_file(string.format('queries/%s/%s.scm', lang, query_name), true) or {}
end

---@param lang string
---@param query_name string
---@return boolean
function utils.has_query_files(lang, query_name)
  if not query_files_cache[lang] then
    query_files_cache[lang] = {}
  end
  if query_files_cache[lang][query_name] == nil then
    local files = runtime_queries(lang, query_name)
    query_files_cache[lang][query_name] = files and #files > 0
  end
  return query_files_cache[lang][query_name]
end

-- cache will auto set the table for each lang if it is nil
---@type table<string, table<string, vim.treesitter.Query>>
local cache = setmetatable({}, mt)

-- Same as `vim.treesitter.query` except will return cached values
---@param lang string
---@param query_name string
---@return vim.treesitter.Query
function utils.get_query(lang, query_name)
  if cache[lang][query_name] == nil then
    cache[lang][query_name] = vim.treesitter.query.get(lang, query_name)
  end

  return cache[lang][query_name]
end

-- Invalidates the query file cache.
--
-- If lang and query_name is both present, will reload for only the lang and query_name.
-- If only lang is present, will reload all query_names for that lang
-- If none are present, will reload everything
---@param lang? string
---@param query_name? string
function utils.invalidate_query_cache(lang, query_name)
  if lang and query_name then
    cache[lang][query_name] = nil
    if query_files_cache[lang] then
      query_files_cache[lang][query_name] = nil
    end
  elseif lang and not query_name then
    query_files_cache[lang] = nil
    for query_name0, _ in pairs(cache[lang]) do
      utils.invalidate_query_cache(lang, query_name0)
    end
  elseif not lang and not query_name then
    query_files_cache = {}
    for lang0, _ in pairs(cache) do
      for query_name0, _ in pairs(cache[lang0]) do
        utils.invalidate_query_cache(lang0, query_name0)
      end
    end
  else
    error('Cannot have query_name by itself!')
  end
end


function utils.get_root_for_position(line, col, root_lang_tree)
  if not root_lang_tree then
    if not utils.has_parser() then
      return
    end

    root_lang_tree = utils.get_parser()
  end

  local lang_tree = root_lang_tree:language_for_range({ line, col, line, col })

  while true do
    for _, tree in pairs(lang_tree:trees()) do
      local root = tree:root()

      if root and vim.treesitter.is_in_node_range(root, line, col) then
        return root, tree, lang_tree
      end
    end

    if lang_tree == root_lang_tree then
      break
    end

    -- This case can happen when the cursor is at the start of a line that ends a injected region,
    -- e.g., the first `]` in the following lua code:
    -- ```
    -- vim.cmd[[
    -- ]]
    -- ```
    lang_tree = lang_tree:parent() -- NOTE: parent() method is private
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end

function utils.ft_to_lang(ft)
  local result = vim.treesitter.language.get_lang(ft)
  if result then
    return result
  else
    ft = vim.split(ft, '.', { plain = true })[1]
    return vim.treesitter.language.get_lang(ft) or ft
  end
end

-- Gets the language of a given buffer
---@param bufnr number? or current buffer
---@return string
function utils.get_buf_lang(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return utils.ft_to_lang(vim.api.nvim_get_option_value('filetype', { buf = bufnr }))
end

local parser_files

function utils.reset_cache()
  parser_files = setmetatable({}, {
    __index = function(tbl, key)
      rawset(tbl, key, vim.api.nvim_get_runtime_file('parser/' .. key .. '.*', false))
      return rawget(tbl, key)
    end,
  })
end

utils.reset_cache()

function utils.has_parser(lang)
  lang = lang or utils.get_buf_lang(vim.api.nvim_get_current_buf())

  if not lang or #lang == 0 then
    return false
  end
  -- HACK: nvim internal API 😎
  if vim._ts_has_language(lang) then
    return true
  end
  return #parser_files[lang] > 0
end

---Find the parser for the current buffer based on filetype
---@param bufnr? integer bufnr of the buffer to find
---@param lang? string language to get parser from
---@return (vim.treesitter.LanguageTree)?
function utils.get_parser(bufnr, lang)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lang = lang or utils.get_buf_lang(bufnr)

  if utils.has_parser(lang) then
    return vim.treesitter.get_parser(bufnr, lang)
  end
end

-- Byte length of node range
---@param node TSNode
---@return number
function utils.node_length(node)
  local _, _, start_byte = node:start()
  local _, _, end_byte = node:end_()
  return end_byte - start_byte
end

utils.get_range = function(match)
  if match.metadata ~= nil then
    return match.metadata.range
  end

  return { match.node:range() }
end

---@class QueryInfo
---@field root TSNode
---@field source integer
---@field start integer
---@field stop integer

---@param bufnr integer
---@param query_name string
---@param root TSNode|nil
---@param root_lang string|nil
---@return vim.treesitter.Query|nil, QueryInfo|nil
function utils.prepare_query(bufnr, query_name, root, root_lang)
  local buf_lang = utils.get_buf_lang(bufnr)

  if not buf_lang then
    return
  end

  local parser = utils.get_parser(bufnr, buf_lang)
  if not parser then
    return
  end

  if not root then
    local first_tree = parser:trees()[1]

    if first_tree then
      root = first_tree:root()
    end
  end

  if not root then
    return
  end

  local range = { root:range() }

  if not root_lang then
    local lang_tree = parser:language_for_range(range)

    if lang_tree then
      root_lang = lang_tree:lang()
    end
  end

  if not root_lang then
    return
  end

  local query = utils.get_query(root_lang, query_name)
  if not query then
    return
  end

  return query,
    {
      root = root,
      source = bufnr,
      start = range[1],
      -- The end row is exclusive so we need to add 1 to it.
      stop = range[3] + 1,
    }
end

-- Given a path (i.e. a List(String)) this functions inserts value at path
---@param object any
---@param path string[]
---@param value any
function utils.insert_to_path(object, path, value)
  local curr_obj = object

  for index = 1, (#path - 1) do
    if curr_obj[path[index]] == nil then
      curr_obj[path[index]] = {}
    end

    curr_obj = curr_obj[path[index]]
  end

  curr_obj[path[#path]] = value
end

---@param query vim.treesitter.Query
---@param bufnr integer
---@param start_row integer
---@param end_row integer
function utils.iter_prepared_matches(query, qnode, bufnr, start_row, end_row)
  -- A function that splits  a string on '.'
  ---@param to_split string
  ---@return string[]
  local function split(to_split)
    local t = {}
    for str in string.gmatch(to_split, "([^.]+)") do
      table.insert(t, str)
    end

    return t
  end

  local matches = query:iter_matches(qnode, bufnr, start_row, end_row, { all = false })

  local function iterator()
    local pattern, match, metadata = matches()
    if pattern ~= nil then
      local prepared_match = {}

      -- Extract capture names from each match
      for id, node in pairs(match) do
        local name = query.captures[id] -- name of the capture in the query
        if name ~= nil then
          local path = split(name .. '.node')
          utils.insert_to_path(prepared_match, path, node)
          local metadata_path = split(name .. '.metadata')
          utils.insert_to_path(prepared_match, metadata_path, metadata[id])
        end
      end

      -- Add some predicates for testing
      ---@type string[][] ( TODO: make pred type so this can be pred[])
      local preds = query.info.patterns[pattern]
      if preds then
        for _, pred in pairs(preds) do
          -- functions
          if pred[1] == 'set!' and type(pred[2]) == 'string' then
            utils.insert_to_path(prepared_match, split(pred[2]), pred[3])
          end
          if pred[1] == 'make-range!' and type(pred[2]) == 'string' and #pred == 4 then
            utils.insert_to_path(
              prepared_match,
              split(pred[2] .. '.node'),
              TSRange.from_nodes(bufnr, match[pred[3]], match[pred[4]])
            )
          end
        end
      end

      return prepared_match
    end
  end
  return iterator
end

---Iterates matches from a query file.
---@param bufnr integer the buffer
---@param query_group string the query file to use
---@param root TSNode? the root node
---@param root_lang? string the root node lang, if known
function utils.iter_group_results(bufnr, query_group, root, root_lang)
  local query, params = utils.prepare_query(bufnr, query_group, root, root_lang)
  if not query then
    return EMPTY_ITER
  end
  assert(params)

  return utils.iter_prepared_matches(query, params.root, params.source, params.start, params.stop)
end

-- Gets a property at path
---@param tbl table the table to access
---@param path string the '.' separated path
---@return table|nil result the value at path or nil
function utils.get_at_path(tbl, path)
  if path == "" then
    return tbl
  end

  local segments = vim.split(path, '.', { plain = true, trimempty = true })
  ---@type table[]|table
  local result = tbl

  for _, segment in ipairs(segments) do
    if type(result) == 'table' then
      ---@type table
      -- TODO: figure out the actual type of tbl
      result = result[segment]
    end
  end

  return result
end

-- Return all nodes corresponding to a specific capture path (like @definition.var, @reference.type)
-- Works like M.get_references or M.get_scopes except you can choose the capture
-- Can also be a nested capture like @definition.function to get all nodes defining a function.
--
---@param bufnr integer the buffer
---@param captures string|string[]
---@param query_group string the name of query group (highlights or injections for example)
---@param root TSNode|nil node from where to start the search
---@param lang string|nil the language from where to get the captures.
---              Root nodes can have several languages.
---@return table|nil
function utils.get_capture_matches(bufnr, captures, query_group, root, lang)
  if type(captures) == 'string' then
    captures = { captures }
  end
  local strip_captures = {} ---@type string[]
  for i, capture in ipairs(captures) do
    if capture:sub(1, 1) ~= '@' then
      error('Captures must start with "@"')
      return
    end
    -- Remove leading '@'.
    strip_captures[i] = capture:sub(2)
  end

  local matches = {}
  for match in utils.iter_group_results(bufnr, query_group, root, lang) do
    for _, capture in ipairs(strip_captures) do
      local insert = utils.get_at_path(match, capture)
      if insert then
        table.insert(matches, insert)
      end
    end
  end
  return matches
end

---@alias CaptureResFn function(string, LanguageTree, LanguageTree): string, string

-- Same as get_capture_matches except this will recursively get matches for every language in the tree.
---@param bufnr integer The buffer
---@param capture_or_fn string|CaptureResFn The capture to get. If a function is provided then that
---                       function will be used to resolve both the capture and query argument.
---                       The function can return `nil` to ignore that tree.
---@param query_type string? The query to get the capture from. This is ignored if a function is provided
---                    for the capture argument.
---@return table[]
function utils.get_capture_matches_recursively(bufnr, capture_or_fn, query_type)
  ---@type CaptureResFn
  local type_fn
  if type(capture_or_fn) == 'function' then
    type_fn = capture_or_fn
  else
    type_fn = function(_, _, _)
      return capture_or_fn, query_type
    end
  end
  local parser = utils.get_parser(bufnr)
  local matches = {}

  if parser then
    parser:for_each_tree(function(tree, lang_tree)
      local lang = lang_tree:lang()
      local capture, type_ = type_fn(lang, tree, lang_tree)

      if capture then
        vim.list_extend(matches, utils.get_capture_matches(bufnr, capture, type_, tree:root(), lang) or {})
      end
    end)
  end

  return matches
end

--- Similar functions from vim.treesitter, but it accepts node as table type, not necessarily a TSNode
local function _cmp_pos(a_row, a_col, b_row, b_col)
  if a_row == b_row then
    if a_col > b_col then
      return 1
    elseif a_col < b_col then
      return -1
    else
      return 0
    end
  elseif a_row > b_row then
    return 1
  end

  return -1
end

local cmp_pos = {
  lt = function(...)
    return _cmp_pos(...) == -1
  end,
  le = function(...)
    return _cmp_pos(...) ~= 1
  end,
  gt = function(...)
    return _cmp_pos(...) == 1
  end,
  ge = function(...)
    return _cmp_pos(...) ~= -1
  end,
  eq = function(...)
    return _cmp_pos(...) == 0
  end,
  ne = function(...)
    return _cmp_pos(...) ~= 0
  end,
}

-- This can be replaced to vim.treesitter.node_contains once Neovim 0.9 is released
-- In 0.8, it only accepts TSNode type and sometimes it causes issues.
function utils.node_contains(node, range)
  local srow_1, scol_1, erow_1, ecol_1 = node:range()
  local srow_2, scol_2, erow_2, ecol_2 = unpack(range)

  -- start doesn't fit
  if cmp_pos.gt(srow_1, scol_1, srow_2, scol_2) then
    return false
  end

  -- end doesn't fit
  if cmp_pos.lt(erow_1, ecol_1, erow_2, ecol_2) then
    return false
  end

  return true
end


--- Get the best match at a given point
--- If the point is inside a node, the smallest node is returned
--- If the point is not inside a node, the closest node is returned (if opts.lookahead or opts.lookbehind is true)
---@param matches table list of matches
---@param row number 0-indexed
---@param col number 0-indexed
---@param opts { lookahead?: boolean; lookbehind?: boolean } lookahead and lookbehind options
function utils.best_match_at_point(matches, row, col, opts)
  local match_length
  local smallest_range
  local earliest_start

  local lookahead_match_length
  local lookahead_largest_range
  local lookahead_earliest_start
  local lookbehind_match_length
  local lookbehind_largest_range
  local lookbehind_earliest_start

  for _, m in pairs(matches) do
    if m.node and vim.treesitter.is_in_node_range(m.node, row, col) then
      local length = utils.node_length(m.node)
      if not match_length or length < match_length then
        smallest_range = m
        match_length = length
      end
      -- for nodes with same length take the one with earliest start
      if match_length and length == smallest_range then
        local start = m.start
        if start then
          local _, _, start_byte = m.start.node:start()
          if not earliest_start or start_byte < earliest_start then
            smallest_range = m
            match_length = length
            earliest_start = start_byte
          end
        end
      end
    elseif opts.lookahead then
      local start_line, start_col, start_byte = m.node:start()
      if start_line > row or start_line == row and start_col > col then
        local length = utils.node_length(m.node)
        if
          not lookahead_earliest_start
          or lookahead_earliest_start > start_byte
          or (lookahead_earliest_start == start_byte and lookahead_match_length < length)
        then
          lookahead_match_length = length
          lookahead_largest_range = m
          lookahead_earliest_start = start_byte
        end
      end
    elseif opts.lookbehind then
      local start_line, start_col, start_byte = m.node:start()
      if start_line < row or start_line == row and start_col < col then
        local length = utils.node_length(m.node)
        if
          not lookbehind_earliest_start
          or lookbehind_earliest_start < start_byte
          or (lookbehind_earliest_start == start_byte and lookbehind_match_length > length)
        then
          lookbehind_match_length = length
          lookbehind_largest_range = m
          lookbehind_earliest_start = start_byte
        end
      end
    end
  end

  if smallest_range then
    if smallest_range.start then
      local start_range = utils.get_range(smallest_range.start)
      local node_range = utils.get_range(smallest_range)
      return { start_range[1], start_range[2], node_range[3], node_range[4] }, smallest_range.node
    else
      return utils.get_range(smallest_range), smallest_range.node
    end
  elseif lookahead_largest_range then
    return utils.get_range(lookahead_largest_range), lookahead_largest_range.node
  elseif lookbehind_largest_range then
    return utils.get_range(lookbehind_largest_range), lookbehind_largest_range.node
  end
end

--- Get the best match at a given point
--- Similar to best_match_at_point but it will search within the @*.outer capture if possible.
--- For example, @function.inner will select the inner part of what @function.outer would select.
--- Without this logic, @function.inner can select the larger context (e.g. the main function)
--- when it's just before the start of the inner range.
--- Or it will look ahead and choose the next inner range instead of selecting the current function
--- when it's just after the end of the inner range (e.g. the 'end' keyword of the function)
--- @param query_string string query to match
--- @param query_group string group from where to search query
--- @param pos integer[]
--- @param bufnr integer
--- @param opts? { lookahead?: boolean; lookbehind?: boolean }
--- @return integer?
--- @return integer[]?
--- @return unknown?
function utils.textobject_at_point(query_string, query_group, pos, bufnr, opts)
  query_group = query_group or 'textobjects'
  opts = opts or {}
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = utils.get_buf_lang(bufnr)
  if not lang then
    return nil, nil, nil
  end

  local row, col = unpack(pos or vim.api.nvim_win_get_cursor(0))
  row = row - 1

  if not string.match(query_string, "^@.*") then
    error('Captures must start with "@"')
    return
  end

  local matches = utils.get_capture_matches_recursively(bufnr, query_string, query_group)
  if string.match(query_string, "^@.*%.outer$") then
    local range, node = utils.best_match_at_point(matches, row, col, opts)
    return bufnr, range, node
  else
    -- query string is @*.inner or @*
    -- First search the @*.outer instead, and then search the @*.inner within the range of the @*.outer
    local query_string_outer = string.gsub(query_string, "%..*", '.outer')
    if query_string_outer == query_string then
      query_string_outer = query_string .. '.outer'
    end

    local matches_outer = utils.get_capture_matches_recursively(bufnr, query_string_outer, query_group)
    if #matches_outer == 0 then
      -- Outer query doesn't exist or doesn't match anything
      -- Return the best match from the entire buffer, just like the @*.outer case
      local range, node = utils.best_match_at_point(matches, row, col, opts)
      return bufnr, range, node
    end

    -- Note that outer matches don't perform lookahead
    local range_outer, node_outer = utils.best_match_at_point(matches_outer, row, col, {})
    if range_outer == nil then
      -- No @*.outer found
      -- Return the best match from the entire buffer, just like the @*.outer case
      local range, node = utils.best_match_at_point(matches, row, col, opts)
      return bufnr, range, node
    end

    local matches_within_outer = {}
    for _, match in ipairs(matches) do
      if utils.node_contains(node_outer, { match.node:range() }) then
        table.insert(matches_within_outer, match)
      end
    end
    if #matches_within_outer == 0 then
      -- No @*.inner found within the range of the @*.outer
      -- Return the best match from the entire buffer, just like the @*.outer case
      local range, node = utils.best_match_at_point(matches, row, col, opts)
      return bufnr, range, node
    else
      -- Find the best match from the cursor position
      local range, node = utils.best_match_at_point(matches_within_outer, row, col, opts)
      if range ~= nil then
        return bufnr, range, node
      else
        -- If failed,
        -- find the best match within the range of the @*.outer
        -- starting from the outer range's start position (not the cursor position)
        -- with lookahead enabled
        range, node = utils.best_match_at_point(matches_within_outer, range_outer[1], range_outer[2], { lookahead = true })
        return bufnr, range, node
      end
    end
  end
end

--------

local LspInterop = {}

local floating_win

-- NOTE: This can be replaced with `vim.islist` once Neovim 0.9 support is dropped
local islist = vim.islist


---Get the preview location
---@param location any
---@param context integer[]|integer
---@return integer?
---@return integer?
function LspInterop.preview_location(location, context)
  -- location may be LocationLink or Location (more useful for the former)
  local uri = location.targetUri or location.uri
  if uri == nil then
    return
  end
  local bufnr = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end

  local range = location.targetRange or location.range
  -- don't include a exclusive 0 character line
  if range['end'].character == 0 then
    range['end'].line = range['end'].line - 1
  end
  if type(context) == 'table' then
    range.start.line = math.min(range.start.line, context[1])
    range['end'].line = math.max(range['end'].line, context[3])
  elseif type(context) == 'number' then
    range['end'].line = math.max(range['end'].line, range.start.line + context)
  end

  local lsp_interop_mod = require('lib.treesitter.lsp_interop')
  local float_opts = lsp_interop_mod.config.data.floating_preview_opts or {}

  local contents = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range['end'].line + 1, false)
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
  local preview_buf, preview_win = vim.lsp.util.open_floating_preview(contents, filetype, float_opts)
  vim.api.nvim_set_option_value('filetype', filetype, { buf = preview_buf })
  return preview_buf, preview_win
end

function LspInterop.make_preview_location_callback(query_string, query_group, context)
  query_group = query_group or 'textobjects'
  context = context or 0
  local callback = function(err, method, result)
    if err then
      error(tostring(err))
    end
    if result == nil or vim.tbl_isempty(result) then
      print('No location found: ' .. (method or 'unknown error'))
      return
    end

    if islist(result) then
      result = result[1]
    end
    local uri = result.uri or result.targetUri
    local range = result.range or result.targetRange
    if not uri or not range then
      return
    end

    local buf = vim.uri_to_bufnr(uri)
    vim.fn.bufload(buf)

    local _, textobject_at_definition =
      utils.textobject_at_point(query_string, query_group, { range.start.line + 1, range.start.character }, buf)

    if textobject_at_definition then
      context = textobject_at_definition
    end

    _, floating_win = LspInterop.preview_location(result, context)
  end

  local signature_handler = function(err, result, handler_context, config)
    callback(err, handler_context.method, result)
  end

  return vim.schedule_wrap(signature_handler)
end

---Show definition of query in a float window
---@param query_string string
---@param query_group? string
---@param lsp_request? string
---@param context? any
---@return table<integer, integer>?
---@return fun()?
function LspInterop.peek_definition_code(query_string, query_group, lsp_request, context)
  query_group = query_group or 'textobjects'
  lsp_request = lsp_request or 'textDocument/definition'
  if vim.tbl_contains(vim.api.nvim_list_wins(), floating_win) then
    vim.api.nvim_set_current_win(floating_win)
  else
    local win_id = vim.api.nvim_get_current_win()
    local params = function(client)
      return vim.lsp.util.make_position_params(win_id, client.offset_encoding)
    end
    return vim.lsp.buf_request(
      0,
      lsp_request,
      params,
      LspInterop.make_preview_location_callback(query_string, query_group, context)
    )
  end
end

LspInterop.utils = utils

return LspInterop
