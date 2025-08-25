--- Highlights handling

---Used to keep track of if LSP reference highlights should be enabled
local highlight_references = false
local highlight_namespace = vim.api.nvim_create_namespace('RefjumpReferenceHighlights')
local reference_hl_name = 'RefjumpReference'

local function create_fallback_hl_group(fallback_hl)
  local hl = vim.api.nvim_get_hl(0, { name = reference_hl_name })

  if vim.tbl_isempty(hl) then
    vim.api.nvim_set_hl(0, reference_hl_name, { link = fallback_hl })
  end
end

local function hl_enable(references, bufnr)
  for _, ref in ipairs(references) do
    local line = ref.range.start.line
    local start_col = ref.range.start.character
    local end_col = ref.range['end'].character

    -- vim.api.nvim_buf_add_highlight(bufnr, highlight_namespace, reference_hl_name, line, start_col, end_col)
    vim.hl.range(bufnr, highlight_namespace, reference_hl_name, { line, start_col }, { line, end_col }, {
      -- {regtype} (string, default: 'v' i.e. charwise) Type of range. See getregtype()
      -- {inclusive} (boolean, default: false) Indicates whether the range is end-inclusive
      -- {priority} (integer, default: vim.hl.priorities.user) Highlight priority
      -- {timeout} (integer, default: -1 no timeout) Time in ms before highlight is cleared
    })
  end

  highlight_references = true
end

---@deprecated Use `hl_enable()` instead
-- local function enable_reference_highlights(references, bufnr)
--   local message = 'refjump.nvim: `enable_reference_highlights()` has been renamed to `hl_enable()`'
--   vim.notify(message, vim.log.levels.WARN)
--   hl_enable(references, bufnr)
-- end

local function hl_disable()
  if not highlight_references then
    vim.api.nvim_buf_clear_namespace(0, highlight_namespace, 0, -1)
  else
    highlight_references = false
  end
end

---@deprecated Use `hl_disable()` instead
-- local function disable_reference_highlights()
--   local message = 'refjump.nvim: `disable_reference_highlights()` has been renamed to `hl_disable()`'
--   vim.notify(message, vim.log.levels.WARN)
--   hl_disable()
-- end

local clear_hl_group = vim.api.nvim_create_augroup('RefjumpReferenceHighlights', { clear = true })

local function auto_clear_reference_highlights()
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'ModeChanged', 'BufLeave' }, {
    callback = hl_disable,
    group = clear_hl_group,
  })
end

--- Jump hanlding

---@alias RefjumpReferencePosition { character: integer, line: integer }
---@alias RefjumpReferenceRange { start: RefjumpReferencePosition, end: RefjumpReferencePosition }
---@alias RefjumpReference { range: RefjumpReferenceRange, uri: string }

---@param ref_pos RefjumpReferencePosition
---@param current_line integer
---@param current_col integer
---@return boolean
local function reference_is_after_current_position(ref_pos, current_line, current_col)
  return ref_pos.line > current_line or (ref_pos.line == current_line and ref_pos.character > current_col)
end

---@param ref_pos RefjumpReferencePosition
---@param current_line integer
---@param current_col integer
---@return boolean
local function reference_is_before_current_position(ref_pos, current_line, current_col)
  return ref_pos.line < current_line or (ref_pos.line == current_line and ref_pos.character < current_col)
end

---Find n:th next reference in `references` from `current_position` where n is
---`count`. Search forward if `forward` is `true`, otherwise search backwards.
---@param references RefjumpReference[]
---@param forward boolean
---@param count integer
---@param current_position integer[]
---@return RefjumpReference
local function find_next_reference(references, forward, count, current_position)
  local current_line = current_position[1] - 1
  local current_col = current_position[2]

  local iter = forward and vim.iter(references) or vim.iter(references):rev()

  return iter
    :filter(function(ref)
      local ref_pos = ref.range.start
      if forward then
        return reference_is_after_current_position(ref_pos, current_line, current_col)
      else
        return reference_is_before_current_position(ref_pos, current_line, current_col)
      end
    end)
    :nth(count)
end

---@param next_reference RefjumpReference
---@param encoding string
local function jump_to(next_reference, encoding)
  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local next_location = { uri = uri, range = next_reference.range }
  -- NOTE: encoding is hard-coded here. It's apparently usually utf-16. But
  -- perhaps it should be calculated dynamically?

  -- vim.lsp.util.jump_to_location(next_location, encoding)
  vim.lsp.util.show_document(next_location, encoding, { focus = true })

  -- Open folds if the reference is inside a fold
  vim.cmd('normal! zv')
end

---@param next_reference RefjumpReference
---@param forward boolean
---@param references RefjumpReference[]
---@param encoding string
local function jump_to_next_reference(next_reference, forward, references, encoding)
  -- If no reference is found, loop around
  if not next_reference then
    next_reference = forward and references[1] or references[#references]
  end

  if next_reference then
    jump_to(next_reference, encoding)
  else
    vim.notify('refjump.nvim: Could not find the next reference', vim.log.levels.WARN)
  end
end

---@param references RefjumpReference[]
---@param forward boolean
---@param count integer
---@param current_position integer[]
---@param encoding string
local function jump_to_next_reference_and_highlight(references, forward, count, current_position, encoding)
  local next_reference = find_next_reference(references, forward, count, current_position)
  jump_to_next_reference(next_reference, forward, references, encoding)

  -- if require('refjump').get_options().highlights.enable then
  --   require('refjump.highlight').enable(references, 0)
  -- end

  hl_enable(references, 0)
end

---Move cursor from `current_position` to the next LSP reference in the current
---buffer if `forward` is `true`, otherwise move to the previous reference.
---
---If `references` is not `nil`, `references` is used to determine next
---position. If `references` is `nil` they will be requested from the LSP
---server and passed to `with_references`.
---@param current_position integer[]
---@param opts { forward: boolean }
---@param count integer
---@param client_id integer client id of the lsp
---@param references? RefjumpReference[]
---@param with_references? function(RefjumpReference[]) Called if `references` is `nil` with LSP references for item at `current_position`
local function reference_jump_from(current_position, opts, count, references, client_id, with_references)
  opts = opts or { forward = true }

  local client = vim.lsp.get_client_by_id(client_id)
  -- If no client, 'utf-16' seems like the most appropriate default
  local encoding = 'utf-16'
  if client then
    encoding = client.offset_encoding
  end

  -- If references have already been computed (i.e. we're repeating the jump)
  if references then
    jump_to_next_reference_and_highlight(references, opts.forward, count, current_position, encoding)
    return
  end

  local params = vim.lsp.util.make_position_params(0, encoding)
  local lsp_request_handler = function(err, refs, _)
    if err then
      vim.notify('refjump.nvim: LSP Error: ' .. err.message, vim.log.levels.ERROR)
      return
    end

    if not refs or vim.tbl_isempty(refs) then
      -- if require('refjump').get_options().verbose then
      --   vim.notify('No references found', vim.log.levels.INFO)
      -- end
      vim.notify('No references found', vim.log.levels.INFO)
      return
    end

    table.sort(refs, function(a, b)
      return a.range.start.line < b.range.start.line
    end)

    jump_to_next_reference_and_highlight(refs, opts.forward, count, current_position, encoding)

    if with_references then
      with_references(refs)
    end
  end

  -- The client should be valid unless terminated in the small window from function call
  -- to reference_jump and the moment this is executed. In such case (althogh unlikely)
  -- Default to the private function `vim.lsp.buf_request` as it should try to get a
  -- valid lsp client that supports the requested method and then call client:request on it.

  if client then
    -- We call `textDocument/documentHighlight` here instead of
    -- `textDocument/references` for performance reasons. The latter searches the
    -- entire workspace, but `textDocument/documentHighlight` only searches the
    -- current buffer, which is what we want.
    client:request('textDocument/documentHighlight', params, lsp_request_handler)
  else
    -- This function is private and probably we shouldn't rely on it.
    vim.lsp.buf_request(0, 'textDocument/documentHighlight', params, lsp_request_handler)
  end
end

---Move cursor to next LSP reference in the current buffer if `forward` is
---`true`, otherwise move to the previous reference.
---
---If `references` is not `nil`, `references` is used to determine next
---position. If `references` is `nil` they will be requested from the LSP
---server and passed to `with_references`.
---@param opts { forward: boolean }
---@param references? RefjumpReference[]
---@param client_id integer client id of the lsp
---@param with_references? fun(refs: RefjumpReference[]) Called if `references` is `nil` with LSP references for item at `current_position`
local function reference_jump(opts, references, client_id, with_references)
  local current_position = vim.api.nvim_win_get_cursor(0)
  local count = vim.v.count1
  reference_jump_from(current_position, opts, count, references, client_id, with_references)
end

-- Start highlights

local started = false

local start = function()
  if started then
    return
  end

  started = true

  -- highlights enable
  create_fallback_hl_group('LspReferenceText')

  -- highlights auto_clear
  auto_clear_reference_highlights()
end

local stop = function()
  started = false
  clear_hl_group = vim.api.nvim_create_augroup('RefjumpReferenceHighlights', { clear = true })
end

return {
  reference_jump = reference_jump,
  reference_jump_from = reference_jump_from,
  start = start,
  stop = stop,
}
