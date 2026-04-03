--- Globals
--- b:qfpeek_floatwin: Current floating win open
--- g:qfpeek_floatwin_opts: options for floating window for preview
--- g:qfpeek_map: keymap to show preview ('K' by default)
--- g:qfpeek_map_ignore: Flag to suppress setting keymaps (suppress only if set to 0)

local ns_qfpeek = 'QfPeek'
local api = vim.api
local ns = api.nvim_create_namespace(ns_qfpeek)
local augroup = api.nvim_create_augroup(ns_qfpeek, {})

local M = {
  ns = ns_qfpeek,
}

local function safe_set_win_option(win, name, value)
  pcall(vim.api.nvim_set_option_value, name, value, { win = win })
end

-- local function safe_set_buf_option(buf, name, value)
--   pcall(vim.api.nvim_set_option_value, name, value, { buf = buf })
-- end

---@param buf number
---@param enter boolean
---@param opts? vim.api.keyset.win_config
---@return number win_id 0 if failed
local function open_win(buf, enter, opts)
  ---@type vim.api.keyset.win_config
  local default_opts = {
    relative = 'win',
    win = api.nvim_get_current_win(),
    anchor = 'SW',
    row = -1,
    col = 1,
    width = api.nvim_win_get_width(0),
    height = vim.o.previewheight,
    title = ns_qfpeek,
    title_pos = 'center',
    border = 'single',
    style = 'minimal',
  }
  opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  local win = api.nvim_open_win(buf, enter, opts)
  api.nvim_create_autocmd('WinLeave', {
    group = augroup,
    callback = function()
      if api.nvim_get_current_win() == win then
        api.nvim_win_close(win, true)
      end
      pcall(api.nvim_clear_autocmds, { group = augroup })
    end,
  })

  api.nvim_win_call(win, function()
    safe_set_win_option(win, 'wrap', false)
    safe_set_win_option(win, 'number', false)
    safe_set_win_option(win, 'relativenumber', false)
    safe_set_win_option(win, 'signcolumn', 'no')
    safe_set_win_option(win, 'winbar', '')
  end)

  return win
end

---Handle case of floating window already showing
---and move cursor to it
---@param floatwin integer
local function on_win_focus(floatwin)
  api.nvim_set_current_win(floatwin)

  local function del_keymaps()
    pcall(vim.keymap.del, 'n', 'q', {})
    pcall(vim.keymap.del, 'n', '<esc>', {})
  end

  local function close_win_cb()
    if api.nvim_win_is_valid(floatwin) then
      api.nvim_win_close(floatwin, true)
      del_keymaps()
    end
  end

  local function create_keymaps()
    del_keymaps()
    vim.keymap.set('n', 'q', close_win_cb, { desc = '[QfPeek] close floating window', silent = true })
    vim.keymap.set('n', '<esc>', close_win_cb, { desc = '[QfPeek] close floating window', silent = true })
  end

  ---helper callback to run on close/leave related autocmd
  ---@param info vim.api.keyset.create_autocmd.callback_args
  local function autocmd_cb(info)
    -- Remove keymap
    del_keymaps()

    ---@type integer
    local qf_win = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(w)
      return vim.fn.win_gettype(w) == 'quickfix'
    end)

    -- Then check if cursor can move back to qf
    if api.nvim_win_is_valid(qf_win) then
      api.nvim_set_current_win(qf_win)
    end
  end

  api.nvim_win_call(floatwin, function()
    -- Keymap to close floating window
    create_keymaps()

    -- Cleanup on_close
    api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(floatwin),
      group = augroup,
      callback = autocmd_cb,
    })

    api.nvim_create_autocmd('WinLeave', {
      pattern = '*',
      group = augroup,
      callback = function(info)
        local cur_win = api.nvim_get_current_win()
        if cur_win ~= floatwin then
          return
        end

        del_keymaps()
      end,
    })

    api.nvim_create_autocmd('WinEnter', {
      pattern = '*',
      group = augroup,
      callback = function(info)
        local cur_win = api.nvim_get_current_win()
        if cur_win ~= floatwin then
          return
        end

        create_keymaps()
      end,
    })
  end)
end

---@class qfpeek.getqflist.return
---@field changedtick integer
---@field context string
---@field id integer
---@field idx integer
---@field items vim.quickfix.entry[]
---@field nr integer
---@field qfbufnr integer
---@field quickfixtextfunc string
---@field size integer
---@field title string
---@field winid integer

function M.on_cmd()
  local qf_buf = api.nvim_get_current_buf()

  local line = vim.fn.line('.') -- 1-based line index
  local is_loc_list = vim.fn.getwininfo(api.nvim_get_current_win())[1].loclist == 1
  ---@type fun(opts: vim.fn.setqflist.what): qfpeek.getqflist.return
  local get_qf_list = is_loc_list and function(...)
    return vim.fn.getloclist(0, ...)
  end or vim.fn.getqflist
  local items = get_qf_list({ idx = line, all = true }).items
  local item = items[1]
  if not item then
    return
  end
  local buf, lnum, end_lnum, col, end_col = item.bufnr, item.lnum, item.end_lnum, item.col, item.end_col
  ---@cast buf integer

  --- Either create a new floating window for preview
  --- or jump to it if already visible

  ---@type integer
  local floatwin
  if not vim.b.qfpeek_floatwin or not api.nvim_win_is_valid(vim.b.qfpeek_floatwin) then
    ---@type vim.api.keyset.win_config|nil
    local opts = vim.g.qfpeek_floatwin_opts
    floatwin = open_win(buf, false, opts)
    api.nvim_buf_set_var(qf_buf, 'qfpeek_floatwin', floatwin)
    api.nvim_win_set_var(floatwin, 'qfpeek_floatwin', 1)
    api.nvim_win_set_var(floatwin, 'breadcrumbs_ignore', 1)
  else
    floatwin = vim.b.qfpeek_floatwin
    on_win_focus(floatwin)
    return
  end

  lnum = lnum > 0 and lnum or 1
  col = col > 0 and col or 1
  api.nvim_win_set_cursor(floatwin, { lnum, col - 1 })
  local function close_float_win()
    if api.nvim_win_is_valid(floatwin) then
      api.nvim_win_close(floatwin, true)
    end
  end
  

  end_lnum = end_lnum > 0 and end_lnum or lnum
  end_col = end_col > 0 and end_col or col
  vim.hl.range(buf, ns, 'Substitute', { lnum - 1, col - 1 }, { end_lnum - 1, end_col - 1 })
  api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(floatwin),
    -- group = augroup,
    once = true,
    callback = function()
      if vim.api.nvim_get_current_win() ~= floatwin then
        return
      end

      api.nvim_buf_clear_namespace(buf, ns, lnum - 1, end_lnum)
    end,
  })
  api.nvim_create_autocmd('CursorMoved', {
    buffer = qf_buf,
    -- group = augroup,
    once = true,
    callback = close_float_win,
  })

  return {
    win = floatwin,
    close = close_float_win,
  }
end

return M
