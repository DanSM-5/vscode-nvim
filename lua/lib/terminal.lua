--- Constants for the terminal module
local terminal_const = {
  interactive = 'interactive_term',
  static = 'static_term',
  filetype = 'lib_term',
  name = 'lib_term',
  term_win = 'term_win',
  term_buf = 'term_buf',
  float_name = 'float_term',
  win_name = 'win_term',
}

local function safe_set_win_option(win, name, value)
  pcall(vim.api.nvim_set_option_value, name, value, { win = win, scope = 'local' })
end

local function safe_set_buf_option(buf, name, value)
  pcall(vim.api.nvim_set_option_value, name, value, { buf = buf, scope = 'local' })
end

---@class terminal.jobstart.opts
---@field cwd? string Working directory to start the terminal
---@field env? table<string, string> Pass to add variables to environment
---@field clear_env? boolean Use clear environment instead of merging
---@field on_exit? fun(jobId: integer, code: integer, event: 'exit')
---@field on_stdout? fun(channelId: integer, data: string[], name: 'stdout')
---@field on_stderr? fun(channelId: integer, data: string[], name: 'stderr')
---@field stdin? 'pipe'|'null' string value 'pipe' to connect the job's stdin to a channel or 'null' to disconnect stdin
---@field stderr_buffered? boolean collect data until EOF (stream close)
---@field stdout_buffered? boolean collect data until EOF (stream close)

---@class terminal.jobstart.int_opts: terminal.jobstart.opts
---@field pty? boolean if this is a pty terminal
---@field term? boolean spawns in pseudo terminal session. Implies 'pty'

-- -@field on_stdin? fun(channelId: integer, data: string[], name: 'stdin')

-- TODO: should on_end include std error?

---@class terminal.float_opts
---@field cmd string|string[] command to execute
---@field term? terminal.jobstart.opts
---@field float? vim.api.keyset.win_config
---@field on_end? fun(lines: string[]) callback to be called at the end with full stdout
---@field ft? string custom filetype to use
---@field bt? string custom buftype to use
---@field name? string name to be used in buffer
---@field keep? boolean keep buffer/window open after the process exits (user handles closing)

---@class terminal.win_opts
---@field cmd string|string[] command to execute
---@field term? terminal.jobstart.opts
---@field fullscreen? boolean open the terminal in a new tabpage with a single window
---@field on_end? fun(lines: string[]) callback to be called at the end with full stdout
---@field ft? string custom filetype to use
---@field bt? string custom buftype to use
---@field name? string name to be used in buffer
---@field keep? boolean keep buffer/window open after the process exits (user handles closing)

---@class terminal.output.window
---@field win integer winrn of floating window
---@field buf integer bufnr of floating window

---@class terminal.output
---@field jobid integer jobId of the process
---@field win integer winrn of floating window
---@field buf integer bufnr of floating window
---@field close fun() function to close the window

---Get floating term config
---@param config vim.api.keyset.win_config
---@return vim.api.keyset.win_config
local get_float_config = function(config)
  local new_config = vim.tbl_deep_extend('force', {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    row = math.floor(vim.o.lines * 0.1),
    col = math.floor(vim.o.columns * 0.1),
    style = 'minimal',
    border = 'rounded',
  } --[[@as vim.api.keyset.win_config]], config)

  return new_config
end

---Options for creating terminal buffer
---@param opts terminal.float_opts
---@return integer winrn
---@return integer bufnr
local function create_win_buf(opts)
  local config = get_float_config(opts.float)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, config)
  return buf, win
end

---Set options on terminal
---@param opts terminal.float_opts
---@param out terminal.output.window
---@param is_float? boolean
local function set_options(opts, out, is_float)
  local buf, win = out.buf, out.win

  -- Set buffer and window variables
  vim.api.nvim_buf_set_var(buf, terminal_const.term_buf, buf)
  vim.api.nvim_win_set_var(win, terminal_const.term_win, win)
  vim.api.nvim_win_set_var(win, 'breadcrumbs_ignore', 1)

  -- buffer options
  safe_set_buf_option(buf, 'buftype', 'nofile')
  safe_set_buf_option(buf, 'bufhidden', 'hide')
  safe_set_buf_option(buf, 'swapfile', false)
  safe_set_buf_option(buf, 'modifiable', false)
  safe_set_buf_option(buf, 'filetype', opts.ft or terminal_const.filetype)

  safe_set_win_option(win, 'wrap', true)
  safe_set_win_option(win, 'number', false)
  safe_set_win_option(win, 'spell', false)
  safe_set_win_option(win, 'foldenable', false)
  safe_set_win_option(win, 'relativenumber', false)
  safe_set_win_option(win, 'signcolumn', 'no')
  safe_set_win_option(win, 'conceallevel', 3)
  safe_set_win_option(win, 'colorcolumn', '')

  local is_transparent = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg == nil
  if is_float and is_transparent then
    -- Make float transparent as well
    safe_set_win_option(win, 'winhighlight', 'NormalFloat:Normal')
  end

  -- TODO: Add backdrop when there is background
  --
  --   if has_bg and self.opts.backdrop and self.opts.backdrop < 100 and vim.o.termguicolors then
  --   self.backdrop_buf = vim.api.nvim_create_buf(false, true)
  --   self.backdrop_win = vim.api.nvim_open_win(self.backdrop_buf, false, {
  --     relative = 'editor',
  --     width = vim.o.columns,
  --     height = vim.o.lines,
  --     row = 0,
  --     col = 0,
  --     style = 'minimal',
  --     focusable = false,
  --     zindex = self.opts.zindex - 1,
  --   })
  --   vim.api.nvim_set_hl(0, 'FloatingBackdrop', { bg = "#000000", default = true })
  --   local utils = require('utils.nvim')
  --   utils.wo(self.backdrop_win, 'winhighlight', 'Normal:FloatingBackdrop')
  --   utils.wo(self.backdrop_win, 'winblend', self.opts.backdrop)
  --   vim.bo[self.backdrop_buf].buftype = 'nofile'
  --   vim.bo[self.backdrop_buf].filetype = 'float_backdrop'
  -- end
end

---Validate options for float_term
---@param opts terminal.float_opts
local function validate_float_opts(opts)
  opts = opts or {}
  opts.float = vim.tbl_deep_extend('force', {}, opts.float or {})
  opts.term = vim.tbl_deep_extend('force', {}, opts.term or {})
end

---Get the proper options for running the command
---@param opts terminal.float_opts
---@return string[] cmd updated to capture stdout
local function get_cmd(opts)
  if not opts.on_end then
    return opts
  end

  ---@type string[]
  local cmd
  local is_win = vim.fn.has('win32') == 1
  local bin = vim.fs.joinpath(vim.fn.stdpath('config'), 'bin')

  if is_win then
    cmd = {
      -- Incantation to make sure powershell runs a script
      -- without loading a whole profile nor blocking it.
      vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell',
      '-NoLogo',
      '-NonInteractive',
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      vim.fs.joinpath(bin, 'run.ps1'),
    }
  else
    cmd = { vim.fs.joinpath(bin, 'run.sh') }
  end

  local opts_cmd = vim.islist(opts.cmd) and opts.cmd or {
    vim.split(opts.cmd, ' ', { plain = true, trimempty = true })
  }
  ---@cast opts_cmd string[]

  vim.list_extend(cmd, opts_cmd)

  return cmd
end

---@param opts terminal.float_opts options for the terminal
---@return terminal.output output values to control float terminal
local function call_float(opts)
  validate_float_opts(opts)

  local buf, win = create_win_buf(opts)
  local term_opts = vim.tbl_deep_extend('force', opts.term or {}, { pty = true, term = true })
  ---@cast term_opts terminal.jobstart.int_opts

  set_options(opts, { win = win, buf = buf }, true)
  pcall(vim.api.nvim_buf_set_name, buf, opts.name or terminal_const.float_name)

  local term_autocmd_group = vim.api.nvim_create_augroup(('float_term_%d_%d'):format(win, buf), { clear = true })

  vim.api.nvim_create_autocmd('TermOpen', {
    once = true,
    buffer = buf,
    group = term_autocmd_group,
    callback = function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd.startinsert()
      end)
    end,
  })

  local id = vim.fn.jobstart(opts.cmd, {
    cwd = term_opts.cwd,
    env = term_opts.env,
    clear_env = term_opts.clear_env,
    pty = term_opts.pty,
    term = term_opts.term,
    on_stderr = term_opts.on_stderr,
    on_stdout = term_opts.on_stdout,
    stdin = term_opts.stdin,
    stdout_buffered = term_opts.stdout_buffered,
    stderr_buffered = term_opts.stderr_buffered,
    on_exit = term_opts.on_exit,
  })

  local function close()
    pcall(vim.fn.jobstop, id)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    pcall(vim.api.nvim_win_close, win, true)
    pcall(vim.api.nvim_clear_autocmds, { group = term_autocmd_group })
    vim.cmd.checktime()
  end

  local out = {
    close = close,
    buf = buf,
    win = win,
    jobId = id,
  }

  vim.api.nvim_create_autocmd('TermClose', {
    once = true,
    buffer = buf,
    callback = function()
      if opts.keep then
        -- Leave terminal mode so the user can read the output and
        -- decide when to close the buffer/window themselves.
        pcall(vim.cmd.stopinsert)
        return
      end
      close()
    end,
  })

  return out
end

---@param opts terminal.float_opts options for the terminal
---@return terminal.output output values to control float terminal
local function float_term(opts)
  validate_float_opts(opts)

  --- no need to capture stdout so call float directly
  if not opts.on_end then
    return call_float(opts)
  end

  --- Wrap to capture stdout

  -- shallow clone to avoid mutating options too much
  ---@type terminal.float_opts
  opts = vim.tbl_deep_extend('force', {}, opts)

  -- Wrap command
  opts.cmd = get_cmd(opts)
  ---@type string
  local tempfile = vim.fn.tempfile()
  local on_end = opts.on_end --[[@as fun(data: string[])]]

  -- Handle on_end
  local capture_on_exit = function()
    if not vim.uv.fs_stat(tempfile) then
      pcall(on_end, {})
      return
    end

    ---@type boolean, string[]
    local ok, lines = pcall(vim.fn.readfile, tempfile)
    if not ok then
      pcall(on_end, {})
      return
    end

    -- pcall(vim.uv.fs_unlink, tempfile)
    pcall(os.remove, tempfile)
    pcall(on_end, lines)
  end

  -- Override term.on_exit if exists
  if opts.term.on_exit then
    local opts_on_exit = opts.term.on_exit
    opts.term.on_exit = function(...)
      ---@diagnostic disable-next-line
      opts_on_exit(...)
      capture_on_exit()
    end
  else
    opts.term.on_exit = capture_on_exit
  end

  -- Inject environment with path to output file to read at the end
  opts.term.env = vim.tbl_deep_extend('force', opts.term.env or {}, {
    CMD_OUTPUT = tempfile,
  })

  -- Call float with injected opts
  return call_float(opts)
end

---Create the window/buffer for win_term according to the rules:
--- - if fullscreen: open new tabpage with single window
--- - else if there is only one window in current tabpage: open vertical split
--- - else: use current focused window
---@param opts terminal.win_opts
---@return integer buf newly created scratch buffer
---@return integer win window the buffer is displayed in
---@return integer? prev_buf previous buffer of the reused window (only when reusing an existing split)
local function create_win(opts)
  ---@type integer?
  local prev_buf = nil

  if opts.fullscreen then
    vim.cmd.tabnew()
  else
    -- winlayout returns e.g. {'leaf', 1019} for a single visible window,
    -- or {'row'|'col', { ... }} when there are splits. Unlike
    -- nvim_tabpage_list_wins, it ignores floating windows.
    local layout = vim.fn.winlayout()
    if layout[1] == 'leaf' then
      vim.cmd.vsplit()
    else
      -- Reusing the currently focused window: remember its buffer so we
      -- can restore it once the terminal closes (preserving layout).
      prev_buf = vim.api.nvim_win_get_buf(0)
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  return buf, win, prev_buf
end

---Validate options for win_term
---@param opts terminal.win_opts
local function validate_win_opts(opts)
  opts = opts or {}
  opts.term = vim.tbl_deep_extend('force', {}, opts.term or {})
end

---@param opts terminal.win_opts options for the terminal
---@return terminal.output output values to control the terminal
local function call_win(opts)
  validate_win_opts(opts)

  local buf, win, prev_buf = create_win(opts)
  local term_opts = vim.tbl_deep_extend('force', opts.term or {}, { pty = true, term = true })
  ---@cast term_opts terminal.jobstart.int_opts

  ---@type terminal.float_opts
  local set_opts = { cmd = opts.cmd, ft = opts.ft, bt = opts.bt, name = opts.name }
  set_options(set_opts, { win = win, buf = buf }, false)
  pcall(vim.api.nvim_buf_set_name, buf, opts.name or terminal_const.win_name)

  local term_autocmd_group = vim.api.nvim_create_augroup(('win_term_%d_%d'):format(win, buf), { clear = true })

  vim.api.nvim_create_autocmd('TermOpen', {
    once = true,
    buffer = buf,
    group = term_autocmd_group,
    callback = function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd.startinsert()
      end)
    end,
  })

  local id = vim.fn.jobstart(opts.cmd, {
    cwd = term_opts.cwd,
    env = term_opts.env,
    clear_env = term_opts.clear_env,
    pty = term_opts.pty,
    term = term_opts.term,
    on_stderr = term_opts.on_stderr,
    on_stdout = term_opts.on_stdout,
    stdin = term_opts.stdin,
    stdout_buffered = term_opts.stdout_buffered,
    stderr_buffered = term_opts.stderr_buffered,
    on_exit = term_opts.on_exit,
  })

  local function close()
    pcall(vim.fn.jobstop, id)

    if prev_buf and vim.api.nvim_win_is_valid(win) then
      -- Reused an existing split: keep the window, restore the previous
      -- buffer if it still exists, otherwise fall back to the next buffer
      -- in the buffer list. Either way the window must remain.
      if vim.api.nvim_buf_is_valid(prev_buf) then
        pcall(vim.api.nvim_win_set_buf, win, prev_buf)
      else
        local scratch = vim.api.nvim_create_buf(true, false)
        pcall(vim.api.nvim_win_set_buf, win, scratch)
        vim.api.nvim_win_call(win, function()
          -- Try to move to a real existing buffer; ignore errors when
          -- there is none to switch to.
          pcall(vim.cmd, 'silent! bnext')
          pcall(vim.api.nvim_buf_delete, scratch, { force = true })
        end)
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    else
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      pcall(vim.api.nvim_win_close, win, true)
    end

    pcall(vim.api.nvim_clear_autocmds, { group = term_autocmd_group })
    vim.cmd.checktime()
  end

  local out = {
    close = close,
    buf = buf,
    win = win,
    jobId = id,
  }

  vim.api.nvim_create_autocmd('TermClose', {
    once = true,
    buffer = buf,
    callback = function()
      if opts.keep then
        -- Leave terminal mode so the user can read the output and
        -- decide when to close the buffer/window themselves.
        pcall(vim.cmd.stopinsert)
        return
      end
      close()
    end,
  })

  return out
end

---@param opts terminal.win_opts options for the terminal
---@return terminal.output output values to control the terminal
local function win_term(opts)
  validate_win_opts(opts)

  --- no need to capture stdout so call directly
  if not opts.on_end then
    return call_win(opts)
  end

  --- Wrap to capture stdout

  -- shallow clone to avoid mutating options too much
  ---@type terminal.win_opts
  opts = vim.tbl_deep_extend('force', {}, opts)

  -- Wrap command (get_cmd only reads opts.cmd / opts.on_end)
  opts.cmd = get_cmd(opts --[[@as terminal.float_opts]])
  ---@type string
  local tempfile = vim.fn.tempfile()
  local on_end = opts.on_end --[[@as fun(data: string[])]]

  -- Handle on_end
  local capture_on_exit = function()
    if not vim.uv.fs_stat(tempfile) then
      pcall(on_end, {})
      return
    end

    ---@type boolean, string[]
    local ok, lines = pcall(vim.fn.readfile, tempfile)
    if not ok then
      pcall(on_end, {})
      return
    end

    pcall(os.remove, tempfile)
    pcall(on_end, lines)
  end

  -- Override term.on_exit if exists
  if opts.term.on_exit then
    local opts_on_exit = opts.term.on_exit
    opts.term.on_exit = function(...)
      ---@diagnostic disable-next-line
      opts_on_exit(...)
      capture_on_exit()
    end
  else
    opts.term.on_exit = capture_on_exit
  end

  -- Inject environment with path to output file to read at the end
  opts.term.env = vim.tbl_deep_extend('force', opts.term.env or {}, {
    CMD_OUTPUT = tempfile,
  })

  return call_win(opts)
end

return {
  get_float_config = get_float_config,
  float_term = float_term,
  win_term = win_term,
}
