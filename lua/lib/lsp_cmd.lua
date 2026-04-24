---@alias lsp.cmd.complete fun(arg_lead: string, cmd: string, pos: integer): string[]
---@alias lsp.cmd.handler fun(args: string[], opts?: {}|nil)

---@class lsp.cmd.subcmd
---@field complete? lsp.cmd.complete
---@field handler lsp.cmd.handler

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

---@type table<string, lsp.cmd.subcmd | nil>
local lsp_subcmds = {
  info = {
    handler = function()
      vim.cmd.checkhealth('vim.lsp')
    end,
  },
  log = {
    handler = function()
      local state_path = vim.fn.stdpath('state')
      local log_path = vim.fs.joinpath(state_path, 'lsp.log')

      vim.cmd.edit(log_path)
    end,
  },
  attach = {
    handler = function(params)
      local name, bufstr = params[1], params[2]
      if not name then
        vim.notify('[:Lsp attach] missing required param "name"', vim.log.levels.WARN)
        return
      end
      local client = vim.lsp.get_clients({ name = name })[1]
      if not client then
        vim.notify(('[:Lsp attach] Unable to find a client with name "%s"'):format(name), vim.log.levels.WARN)
        return
      end

      ---@type integer
      local bufnr = bufstr and tonumber(bufstr) or vim.api.nvim_get_current_buf()
      local success = vim.lsp.buf_attach_client(bufnr, client.id)
      if not success then
        vim.notify(('[:Lsp attach] Unable to attach buf "%d" to client "%s"'):format(bufnr, name), vim.log.levels.WARN)
      end
    end,
    complete = function(param, cmd)
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

      -- Complete non-attached buffers
      -- Give preference to existing client in current buffer
      local client = get_lsp_client(name)
      if not client then
        return {}
      end

      ---@type string[]
      local non_attached_buffers = vim
        .iter(vim.api.nvim_list_bufs())
        :filter(function(buf)
          ---@cast buf integer
          return not client.attached_buffers[buf] and vim.bo[buf].buflisted
        end)
        :map(function (buf)
          ---@cast buf integer
          return tostring(buf)
        end)
        :totable()

      return non_attached_buffers
    end,
  },
  detach = {
    handler = function(params)
      local name, bufstr = params[1], params[2]
      if not name then
        vim.notify('[:Lsp detach] missing required param "name"', vim.log.levels.WARN)
        return
      end

      ---@type integer
      local bufnr = bufstr and tonumber(bufstr) or vim.api.nvim_get_current_buf()

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

      -- Complete non-attached buffers
      -- Give preference to existing client in current buffer
      local client = get_lsp_client(name)
      if not client then
        return {}
      end

      ---@type string[]
      local attached_buffers = vim
        .iter(vim.tbl_keys(client.attached_buffers))
        :filter(function(buf)
          ---@cast buf integer
          return client.attached_buffers[buf]
        end)
        :map(function (buf)
          ---@cast buf integer
          return tostring(buf)
        end)
        :totable()

      return attached_buffers
    end,
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
  },
  restart = {
    handler = function(params)
      run_lsp_cmd('restart', params)
    end,
    complete = function(...)
      return complete_buf_active_lsp(...)
    end,
  },
  stop = {
    handler = function(params)
      run_lsp_cmd('stop', params)
    end,
    complete = function(...)
      return complete_buf_active_lsp(...)
    end,
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
