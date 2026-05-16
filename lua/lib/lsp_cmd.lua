---@alias lsp.cmd.complete fun(arg_lead: string, cmd: string, pos: integer): string[]
---@alias lsp.cmd.handler fun(args: string[], opts?: {}|nil)

---@class lsp.cmd.subcmd
---@field complete? lsp.cmd.complete
---@field handler lsp.cmd.handler
---@field help? string

---@type table<string, lsp.cmd.subcmd | nil>
local lsp_subcmds = {}

---Helper for setting buf options safely
---@param buf integer
---@param name string
---@param value string|integer|boolean|nil
local function safe_set_buf_option(buf, name, value)
  pcall(vim.api.nvim_set_option_value, name, value, { buf = buf, scope = 'local' })
end

---Format any conent into human readable format
---@param ... any
---@return string[]
local function format_content(...)
  local msg = {} ---@type string[]
  for i = 1, select('#', ...) do
    local o = select(i, ...)
    if type(o) == 'string' then
      table.insert(msg, o)
    else
      local tbl_str = vim.inspect(o, { newline = '\n', indent = '  ' })
      local parts = vim.split(tbl_str, '\n')
      vim.list_extend(msg, parts)
    end
  end
  return msg
end

---Set options for the help buffer
---@param buf integer bufnr for the help
local function set_help_buf_opts(buf)
  -- buffer options
  safe_set_buf_option(buf, 'buftype', 'nofile')
  safe_set_buf_option(buf, 'bufhidden', 'hide')
  safe_set_buf_option(buf, 'swapfile', false)
  safe_set_buf_option(buf, 'modifiable', false)
  safe_set_buf_option(buf, 'filetype', 'lua')
  pcall(vim.api.nvim_buf_set_name, buf, 'lsp-help')
end

---Create a help buffer
---@param content any content for the help buffer
---@return integer
local function create_help_buffer(content)
  local buf = vim.api.nvim_create_buf(false, true)
  local parsed_content = format_content(content)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, parsed_content)
  set_help_buf_opts(buf)
  return buf
end


---Complete lsp name
---@param name string|nil
---@return string[]
local function complete_enabled_lsp_name(name)
  local options = vim.tbl_keys(vim.lsp._enabled_configs) --[[@as string[] ]]
  return require('lib.cmd').get_matched(options, ('^%s'):format(name or ''))
end

---Get an lsp client by given name
---@param name string the name of the client
---@return vim.lsp.Client|nil
local function get_lsp_client(name)
  local client = vim.lsp.get_clients({ bufnr = 0, name = name })[1] or vim.lsp.get_clients({ name = name })[1]
  return client
end

---Get names of lsp clients attached to the corrent buffer
---@return string[]
local function get_buf_active_lsp_names()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  return vim
    .iter(clients)
    :map(function(c)
      ---@cast c vim.lsp.Client
      return c.name
    end)
    :totable()
end

---Detach all lsp clients of the current buffer
local function detach_all()
  local buf = vim.api.nvim_get_current_buf()
  local buf_clients = vim.lsp.get_clients({ bufnr = buf, name = name })
  for _, client in ipairs(buf_clients) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

---Resolve a buffer to its bufnr
---@param buf_or_name? string|integer|nil
---@return integer|nil bufnr of the provided identifier or the current buffer
local function resolve_buf(buf_or_name)
  ---@type string|integer
  local defined_buf_or_name = buf_or_name or vim.api.nvim_get_current_buf()
  local converted = tonumber(defined_buf_or_name) --[[@as integer|nil]]

  ---@type integer
  local bufnr = converted and converted or vim.fn.bufnr(defined_buf_or_name --[[@as string]], 0)
  if bufnr == -1 or not vim.api.nvim_buf_is_valid(bufnr) then
    return -- invalid buffer
  end

  return bufnr
end

---Get the list of attached buffers for detaching
---@param client vim.lsp.Client
---@return string[]
local function get_attached_buf_list(client)
  ---@type string[]
  local attached_buffers = vim
    .iter(vim.tbl_keys(client.attached_buffers))
    :filter(function(buf)
      ---@cast buf integer
      return client.attached_buffers[buf] and vim.api.nvim_buf_is_valid(buf)
    end)
    :map(function(buf)
      -- Use `vim.fn.bufname(buf)` instead of `vim.api.nvim_buf_get_name(buf)`
      -- to get path relative to CWD
      local bufname = vim.fn.bufname(buf)
      return vim.fs.normalize(bufname)
    end)
    :totable()

  return attached_buffers
end

---Get the list of detached buffers for attaching
---@param client vim.lsp.Client
---@return string[]
local function get_detached_buf_list(client)
  ---@type string[]
  local non_attached_buffers = vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      ---@cast buf integer
      return not client.attached_buffers[buf] and vim.bo[buf].buflisted and vim.api.nvim_buf_is_valid(buf)
    end)
    :map(function(buf)
      -- Use `vim.fn.bufname(buf)` instead of `vim.api.nvim_buf_get_name(buf)`
      -- to get path relative to CWD
      local bufname = vim.fn.bufname(buf)
      return vim.fs.normalize(bufname)
    end)
    :totable()

  return non_attached_buffers
end

---Get relevant completion candidates for
---attaching or detaching from a lsp client
---@param mode 'attached'|'detached' Mode to get the list of attached or detached buffers
---@param param string The command completion `arg_lead`
---@param cmd string The full command typed
---@return string[] completions candidates (client names / buffers)
local function complete_lsp_att_det(mode, param, cmd)
  local segments = vim.split(cmd, ' ', { plain = true })

  -- Complete lsp name
  if #segments <= 3 then
    return complete_enabled_lsp_name(param)
  end

  local name = segments[3]

  -- Cannot proceed without name
  if not name then
    return {}
  end

  -- Complete buffers
  -- Give preference to existing client in current buffer
  local client = get_lsp_client(name)
  if not client then
    return {}
  end

  if mode == 'attached' then
    return get_attached_buf_list(client)
  else
    return get_detached_buf_list(client)
  end
end

---Complete function for active lsp configs in current buffer
---@param name? string
---@return string[] completions
local function complete_buf_active_lsp(name)
  local options = get_buf_active_lsp_names()
  return require('lib.cmd').get_matched(options, name or '')
end

---Run an `:lsp` command
---@param cmd string command to run
---@param params string[] additional params for the lsp command
local function run_lsp_cmd(cmd, params)
  table.insert(params, 1, cmd)
  vim.cmd.lsp({ args = params })
end

---Get a formatted help table
---@return table<string, string> table containing help of all sub commands
local function get_help_table()
  local help_tbl = {}
  for name, value in pairs(lsp_subcmds) do
    help_tbl[name] = ('[Lsp %s]: %s'):format(name, value.help or 'Subcommand of `Lsp`')
  end
  return help_tbl
end

---@type table<string, lsp.cmd.subcmd | nil>
lsp_subcmds = {
  info = {
    handler = function()
      vim.cmd.checkhealth('vim.lsp')
    end,
    help = 'Same as `:checkhealth vim.lsp`. See `:help LspInfo`.',
  },
  log = {
    handler = function()
      local state_path = vim.fn.stdpath('state')
      local log_path = vim.fs.joinpath(state_path, 'lsp.log')

      vim.cmd.edit(log_path)
    end,
    help = 'Open `lsp.log` file.',
  },
  attach = {
    handler = function(params)
      local name, buf_or_name = params[1], params[2]
      if not name then
        vim.notify('[:Lsp attach] missing required param "name"', vim.log.levels.WARN)
        return
      end
      local client = vim.lsp.get_clients({ name = name })[1]
      if not client then
        vim.notify(
          ('[:Lsp attach] Unable to find a client with name "%s". Use `Lsp start %s`'):format(name, name),
          vim.log.levels.WARN
        )
        return
      end

      local bufnr = resolve_buf(buf_or_name)
      if not bufnr then
        vim.notify(
          ('[:Lsp attach] Unable resolve buffer: "%s"'):format(tostring(buf_or_name or 'nil'), name),
          vim.log.levels.WARN
        )
        return
      end

      local success = vim.lsp.buf_attach_client(bufnr, client.id)
      if not success then
        vim.notify(('[:Lsp attach] Unable to attach buf "%d" to client "%s"'):format(bufnr, name), vim.log.levels.WARN)
      end
    end,
    complete = function(param, cmd)
      return complete_lsp_att_det('detached', param, cmd)
    end,
    help = 'Attach a buffer to the language server: `Lsp attach <lsp> [<buf_or_name>]`',
  },
  detach = {
    handler = function(params)
      local name, buf_or_name = params[1], params[2]
      if not name then
        vim.notify('[:Lsp detach] Detaching all clients!', vim.log.levels.WARN)
        detach_all()
        return
      end

      local bufnr = resolve_buf(buf_or_name)
      if not bufnr then
        vim.notify(
          ('[:Lsp attach] Unable resolve buffer: "%s"'):format(tostring(buf_or_name or 'nil'), name),
          vim.log.levels.WARN
        )
        return
      end

      local client = vim.lsp.get_clients({ name = name, bufnr = bufnr })[1]
      if not client then
        vim.notify(
          ('[:Lsp detach] Unable to find a client with name "%s" attached to buffer "%d"'):format(name, bufnr),
          vim.log.levels.WARN
        )
        return
      end

      vim.lsp.buf_detach_client(bufnr, client.id)
    end,
    complete = function(param, cmd)
      return complete_lsp_att_det('attached', param, cmd)
    end,
    help = 'Detach a buffer from the language server: `Lsp detach [<lsp>] [<buf_or_name>]`. With no args detaches all clients from current buffer.',
  },
  enable = {
    handler = function(params)
      local name = params[1]
      if not name then
        return
      end

      vim.cmd.lsp({ args = { 'enable', name } })
    end,
    complete = function(param, cmd)
      local segments = vim.split(cmd, ' ', { plain = true })
      -- Cannot handle more than 1 parameter for `:Lsp enable <config_name>`
      if #segments > 3 then
        return {}
      end

      ---@type string[]
      local configs = {}
      for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*.lua', true)) do
        local basename = vim.fs.basename(v)
        local config_name = vim.split(basename, '.', { plain = true, trimempty = true })[1]
        if type(config_name) == 'string' and not vim.lsp._enabled_configs[config_name] then
          configs[#configs + 1] = config_name
        end
      end

      return require('lib.cmd').get_matched(configs, param or '')
    end,
    help = 'Enable a lsp by name. Same as `:lsp enable <lsp>`. See `:help lsp-enable`.',
  },
  disable = {
    handler = function(params)
      if #params == 0 then
        return
      end

      run_lsp_cmd('disable', params)
    end,
    complete = function(param)
      return complete_enabled_lsp_name(param)
    end,
    help = 'Disable a lsp by name. Same as `:lsp disable <lsp>`. See `:help lsp-disable`.',
  },
  restart = {
    handler = function(params)
      run_lsp_cmd('restart', params)
    end,
    complete = function(...)
      return complete_buf_active_lsp(...)
    end,
    help = 'Restart clients. Same as `:lsp restart [<lsp>]`. See `:help lsp-restart`.',
  },
  stop = {
    handler = function(params)
      run_lsp_cmd('stop', params)
    end,
    complete = function(...)
      return complete_buf_active_lsp(...)
    end,
    help = 'Stop clients. Same as `:lsp stop [<lsp>]`. See `:help lsp-stop`.',
  },
  help = {
    handler = function(_, opts)
      opts = opts or {}
      local help_tbl = get_help_table()
      if not opts.bang then
        vim.print(help_tbl)
        return
      end

      local win = vim.api.nvim_get_current_win()
      local buf = create_help_buffer(help_tbl)
      vim.api.nvim_win_set_buf(win, buf)
    end,
    help = 'Print this help message.',
  },
}

---Completion function for :Lsp command
---@param param string Current param being typed
---@param cmd string Full cmd string
---@param pos integer Cursor position
local function complete_lsp_cmd(param, cmd, pos)
  local segments = vim.split(cmd, ' ', { plain = true })

  if #segments <= 2 then
    local options = vim.tbl_keys(lsp_subcmds) --[[@as string[] ]]
    return require('lib.cmd').get_matched(options, ('^%s'):format(param))
  end

  local subcmd = lsp_subcmds[segments[2]]
  if subcmd and subcmd.complete then
    return subcmd.complete(param, cmd, pos)
  end

  return {}
end

---Command handler for Lsp command
---@param info vim.api.keyset.create_user_command.command_args
local function cmd(info)
  if #info.fargs == 0 then
    -- NOOP
    return
  end

  local sub = info.fargs[1]
  local subcmd = lsp_subcmds[sub]
  if subcmd == nil then
    vim.notify(('[:Lsp] unknown command "%s"'):format(subcmd), vim.log.levels.WARN)
    return
  end

  local rest = {}
  for i = 2, #info.fargs do
    rest[#rest + 1] = info.fargs[i]
  end

  local opts = { bang = info.bang }
  return subcmd.handler(rest, opts)
end

return {
  cmd = cmd,
  complete = complete_lsp_cmd,
}
