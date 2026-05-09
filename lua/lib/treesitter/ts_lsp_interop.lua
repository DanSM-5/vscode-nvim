---@module 'lib.treesitter.ts_lsp_interop'
---
--- Peek the body of a symbol returned by an LSP definition request inside a
--- floating window. The visible range is widened to the surrounding tree-sitter
--- textobject (one of `@function.outer`, `@function.inner`, `@class.outer`,
--- `@class.inner`).
---
--- This module exposes a single public function: `peek_definition_code`.

local api = vim.api

--- Local stand-in for the soon-to-be-removed `Range4` alias from nvim core.
--- Same shape: `{ start_row, start_col, end_row, end_col }`, all 0-indexed,
--- end-exclusive on the column.
--- TODO(nvim 0.13): re-validate every boundary that converts to/from this
--- alias once `Range4` is gone (see casts inside `smallest_textobject_range`).
---@alias ts_lsp_interop.Range4 [integer, integer, integer, integer]

local TsLspInterop = {}

---Window id of the last opened floating preview, kept so subsequent calls can
---focus it instead of opening a new one (matches the previous behaviour).
---@type integer?
local floating_win

--- Return true when the given range strictly covers (row, col).
---@param range ts_lsp_interop.Range4
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return boolean
local function range_covers(range, row, col)
  local srow, scol, erow, ecol = range[1], range[2], range[3], range[4]
  if row < srow or row > erow then return false end
  if row == srow and col < scol then return false end
  if row == erow and col > ecol then return false end
  return true
end

--- Byte length of a range, used to pick the smallest containing match.
---@param range ts_lsp_interop.Range4
---@param bufnr integer
---@return integer
local function range_byte_length(bufnr, range)
  local start_byte = api.nvim_buf_get_offset(bufnr, range[1]) + range[2]
  local end_byte = api.nvim_buf_get_offset(bufnr, range[3]) + range[4]
  return end_byte - start_byte
end

--- Find the smallest range matching `capture_name` (e.g. `function.outer`)
--- inside the `textobjects` query that contains the given position.
---
--- Honours the `make-range!` directive by reading `metadata[id].range` when
--- present, otherwise falls back to the matched node's own range.
---
---@param bufnr integer
---@param pos [integer, integer] 0-indexed (row, col)
---@param capture_name string capture without the leading `@`
---@param query_group string typically `'textobjects'`
---@return ts_lsp_interop.Range4?
local function smallest_textobject_range(bufnr, pos, capture_name, query_group)
  local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
  if not parser then return nil end
  parser:parse(true)

  local row, col = pos[1], pos[2]
  local best_range, best_len

  parser:for_each_tree(function(tree, lang_tree)
    local query = vim.treesitter.query.get(lang_tree:lang(), query_group)
    if not query then return end

    -- Cache the capture ids whose name matches `capture_name`. Multiple
    -- patterns may share the same name (e.g. one direct, one via make-range!).
    local target_ids = {}
    for id, name in ipairs(query.captures) do
      if name == capture_name then target_ids[id] = true end
    end
    if not next(target_ids) then return end

    local root = tree:root()
    local rsrow, _, rerow, _ = root:range()
    if row < rsrow or row > rerow then return end

    for _, match, metadata in query:iter_matches(root, bufnr, 0, -1) do
      for id in pairs(target_ids) do
        ---@type ts_lsp_interop.Range4?
        local range
        if metadata[id] and metadata[id].range then
          -- `metadata[id].range` is typed as `Range4` by nvim; cast across the
          -- boundary so the rest of the module only deals with the local alias.
          -- TODO(nvim 0.13): re-validate this cast — `Range4` is scheduled for
          -- removal; check what type `metadata[id].range` is annotated as.
          range = metadata[id].range --[[@as ts_lsp_interop.Range4]]
        else
          local nodes = match[id]
          if nodes and nodes[#nodes] then
            local sr, sc, er, ec = nodes[#nodes]:range()
            range = { sr, sc, er, ec }
          end
        end
        if range and range_covers(range, row, col) then
          local len = range_byte_length(bufnr, range)
          if not best_len or len < best_len then
            best_range, best_len = range, len
          end
        end
      end
    end
  end)

  return best_range
end

--- Open a floating preview showing the contents of `location`, expanded so
--- that it spans the full textobject when `range_override` is provided.
---@param location lsp.Location|lsp.LocationLink
---@param range_override ts_lsp_interop.Range4?
---@return integer? bufnr
---@return integer? winid
local function open_preview(location, range_override)
  local uri = location.targetUri or location.uri
  if not uri then return nil end

  local bufnr = vim.uri_to_bufnr(uri)
  if not api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end

  local lsp_range = location.targetRange or location.range
  local start_line = lsp_range.start.line
  local end_line = lsp_range['end'].line
  -- Don't include the trailing exclusive line break.
  if lsp_range['end'].character == 0 then end_line = end_line - 1 end

  if range_override then
    start_line = math.min(start_line, range_override[1])
    end_line = math.max(end_line, range_override[3])
  end

  local lsp_interop_mod = require('lib.treesitter.lsp_interop')
  local float_opts = (lsp_interop_mod.config and lsp_interop_mod.config.data
    and lsp_interop_mod.config.data.floating_preview_opts) or {}

  local contents = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  local filetype = api.nvim_get_option_value('filetype', { buf = bufnr })
  local preview_buf, winid = vim.lsp.util.open_floating_preview(contents, filetype, float_opts)

  -- `open_floating_preview` only enables vim regex syntax; force tree-sitter
  -- highlighting on the preview buffer. Setting the filetype also fires
  -- `FileType` autocmds (LSP attach is not desired here, but TS highlight is).
  if preview_buf and api.nvim_buf_is_valid(preview_buf) then
    api.nvim_set_option_value('filetype', filetype, { buf = preview_buf })
    local lang = vim.treesitter.language.get_lang(filetype) or filetype
    pcall(vim.treesitter.start, preview_buf, lang)
  end

  return preview_buf, winid
end

--- Pick the first usable result from a `vim.lsp.buf_request_all` payload.
---@param results table<integer, { err?: lsp.ResponseError, result: any }>?
---@return lsp.Location|lsp.LocationLink|nil
local function first_location(results)
  if not results then return nil end
  for _, response in pairs(results) do
    local res = response.result
    if res then
      if vim.islist(res) then
        if res[1] then return res[1] end
      else
        return res
      end
    end
  end
  return nil
end

--- Peek the definition of the symbol under the cursor in a floating window,
--- widening the displayed range to the surrounding textobject described by
--- `query_string` (e.g. `'@function.outer'`).
---
---@param query_string string capture name, must start with `@`
---@param query_group? string defaults to `'textobjects'`
---@param lsp_request? string defaults to `'textDocument/definition'`
function TsLspInterop.peek_definition_code(query_string, query_group, lsp_request)
  query_group = query_group or 'textobjects'
  lsp_request = lsp_request or 'textDocument/definition'
  assert(query_string:sub(1, 1) == '@', 'query_string must start with "@"')
  local capture_name = query_string:sub(2)

  if floating_win and vim.tbl_contains(api.nvim_list_wins(), floating_win) then
    api.nvim_set_current_win(floating_win)
    return
  end

  local win_id = api.nvim_get_current_win()
  local make_params = function(client)
    return vim.lsp.util.make_position_params(win_id, client.offset_encoding)
  end

  vim.lsp.buf_request_all(0, lsp_request, make_params, vim.schedule_wrap(function(results)
    local location = first_location(results)
    if not location then
      vim.notify('No location found for ' .. lsp_request, vim.log.levels.INFO)
      return
    end

    local uri = location.targetUri or location.uri
    local lsp_range = location.targetRange or location.range
    if not uri or not lsp_range then return end

    local bufnr = vim.uri_to_bufnr(uri)
    if not api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end

    local override = smallest_textobject_range(
      bufnr,
      { lsp_range.start.line, lsp_range.start.character },
      capture_name,
      query_group
    )

    _, floating_win = open_preview(location, override)
  end))
end

return TsLspInterop
