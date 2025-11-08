local cursor_hi_group = vim.api.nvim_create_augroup('cursor_highlight', { clear = true })
---@type integer
local cursor_hold_id
---@type integer
local clear_cursor_hold_id

local enabled = true

---Set enable or disabled
---@param e boolean
local function set(e)
  enabled = e
end

local function clear_autocmds()
  if cursor_hold_id then
    pcall(vim.api.nvim_del_autocmd, cursor_hold_id)
  end
  if clear_cursor_hold_id then
    pcall(vim.api.nvim_del_autocmd, clear_cursor_hold_id)
  end
end

local function set_autocmds()
  if not enabled then
    return
  end

  clear_autocmds()

  vim.api.nvim_set_hl(0, 'LspReferenceText', {
    -- underline = true,
    -- cterm = { underline = true },
    -- bg = '#4b5263',
    bg = '#4D4D4D',
    force = true,
  })

  vim.api.nvim_create_autocmd({ 'CursorHold' }, {
    group = cursor_hi_group,
    desc = '[CursorHighlight] Highlight references of word under cursor',
    callback = function(opts)
      -- Only run in normal mode
      if vim.fn.mode() ~= 'n' then
        return
      end

      local clients = vim.lsp.get_clients({
        bufnr = opts.buf or 0,
        method = 'textDocument/documentHighlight',
      })

      if #clients == 0 then
        return
      end

      pcall(vim.lsp.buf.clear_references)
      pcall(vim.lsp.buf.document_highlight)
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorHoldI', 'CursorMoved', 'CursorMovedI' }, {
    group = cursor_hi_group,
    desc = '[CursorHighlight] Cleanup references highlight',
    callback = function()
      pcall(vim.lsp.buf.clear_references)
    end
  })
end

return {
  set = set,
  set_autocmds = set_autocmds,
  clear_autocmds = clear_autocmds,
}
