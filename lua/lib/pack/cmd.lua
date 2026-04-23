---@alias pack.cmd.complete fun(arg_lead: string, cmd: string, pos: integer): string[]
---@alias pack.cmd.handler fun(plugins: string[], opts: { force?: boolean })

---@class pack.cmd.subcmd
---@field complete? pack.cmd.complete
---@field handler pack.cmd.handler

---Get lockfile file path and flag if it exits
---@return string lockfile path
---@return boolean exists is there lockfile?
local get_lockfile_path = function()
  local config_path = vim.fn.stdpath('config')
  local lockfile = vim.fs.joinpath(config_path, 'nvim-pack-lock.json')

  if vim.uv.fs_stat(lockfile) then
    return lockfile, true
  end

  return lockfile, false
end

---@type table<string, { handler: fun() } | nil>
local pack_lockfile_subcmds = {
  edit = {
    handler = function()
      local lockfile, exists = get_lockfile_path()

      if exists then
        vim.cmd.edit(lockfile)
      else
        vim.notify(('[:Pack] Lockfile not found in "%s"'):format(lockfile), vim.log.levels.WARN)
      end
    end,
  },
  status = {
    handler = function()
      local lockfile, exists = get_lockfile_path()
      if exists then
        vim.cmd(('Git diff HEAD %s'):format(lockfile))
      else
        vim.notify(('[:Pack] Lockfile not found in "%s"'):format(lockfile), vim.log.levels.WARN)
      end
    end,
  },
  update = {
    handler = function()
      local lockfile, exists = get_lockfile_path()
      if exists then
        vim.cmd(('Git add %s'):format(lockfile))
        -- Commit with default message but open editor for confirmation
        vim.cmd(('Git commit -m "chore(deps): update deps `pack`" -e %s'):format(lockfile))
      end
    end,
  },
  clear = {
    handler = function()
      local lockfile, exists = get_lockfile_path()
      if exists then
        vim.cmd(('Git checkout -- %s'):format(lockfile))
      end
    end,
  },
}

---Complete single plugin
---@param arg_lead string
---@param cmd string
---@return string[]
local function pack_complete_single(arg_lead, cmd)
  local sections = vim.split(cmd, ' ', { plain = true })
  if #sections > 3 then
    return {}
  end

  return require('lib.pack.core').complete_packages(arg_lead)
end

---Get spec for single plugin
---@param plugins string[]
---@return vim.pack.PlugData|nil
local function pack_get_single_spec(plugins)
  -- Assume that only a single plugin will arrive here
  local plugin_name = plugins[1]
  local plugin_specs = vim.pack.get({ plugin_name })
  local spec = plugin_specs[1]

  if not spec or not spec.path or not vim.uv.fs_stat(spec.path) then
    return
  end

  return spec
end

---@type table<string, pack.cmd.subcmd | nil>
local pack_subcmds = {
  update = {
    handler = function(plugins, opts)
      -- If there are plugins follow the regular path
      if plugins and #plugins > 0 then
        return require('lib.pack.core').update(plugins, opts)
      end

      -- update all if forced
      if opts.force then
        -- require('lib.pack.core').update(plugins, { force = true })
        return require('lib.pack.core').update(plugins, opts)
      end

      -- otherwise confirm first
      local prompt = 'Do you want to update ALL packages?'
      local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)

      if choice == 1 then
        vim.notify('[:Pack] Updating everything.', vim.log.levels.INFO)
        return require('lib.pack.core').update(nil, opts)
      else
        vim.notify('Update aborted.', vim.log.levels.WARN)
      end
    end,
    complete = function(...)
      return require('lib.pack.core').complete_packages(...)
    end,
  },
  install = {
    handler = function(plugins)
      return require('lib.pack.core').install(plugins)
    end,
  },
  delete = {
    handler = function(...)
      return require('lib.pack.core').delete(...)
    end,
    complete = function(...)
      return require('lib.pack.core').complete_packages(...)
    end,
  },
  explore = {
    handler = function(plugins)
      local spec = pack_get_single_spec(plugins)

      if not spec then
        return
      end

      ---@type (string?)|string[]
      local shell = os.getenv('SHELL')

      if not shell then
        -- likely windows 😅
        if vim.fn.has('win32') == 1 then
          shell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
        else
          -- shell = '/bin/bash'
          shell = { '/usr/bin/env', 'bash' }
        end
      end

      require('lib.terminal').float_term({
        cmd = shell,
        term = { cwd = spec.path },
      })
    end,
    complete = pack_complete_single,
  },
  log = {
    handler = function(plugins)
      local spec = pack_get_single_spec(plugins)

      if not spec then
        return
      end

      require('lib.git_preview').fshow(spec.path)
    end,
    complete = pack_complete_single,
  },
  inspect = {
    handler = function(plugins)
      local single = plugins[1]
      if not single then
        return
      end

      local vim_pack = vim.pack.get({ single })[1]
      local lib_pack = require('lib.pack.core').load_tbl[single]

      vim.print({
        vim_pack = vim_pack,
        lib_pack = lib_pack,
      })
    end,
    complete = pack_complete_single,
  },
  restore = {
    handler = function(_, opts)
      local _, exists_lockfile = get_lockfile_path()
      if not exists_lockfile then
        return vim.notify(
          '[:Pack] Cannot restore because there is no lockfile "nvim-pack-lock.json"',
          vim.log.levels.ERROR
        )
      end

      if opts.force then
        return require('lib.pack.core').restore()
      end

      -- otherwise confirm first
      local prompt = 'Do you want to restore ALL packages?'
      local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)

      if choice == 1 then
        vim.notify('[:Pack] Restoring to current lockfile values.', vim.log.levels.INFO)
        return require('lib.pack.core').restore()
      else
        vim.notify('[:Pack] Restore aborted.', vim.log.levels.WARN)
      end
    end,
  },
  lockfile = {
    handler = function(options)
      local selection = options[1]
      local subcmd = pack_lockfile_subcmds[selection]
      if subcmd == nil then
        vim.notify('[:Pack] Unknown "lockfile" option', vim.log.levels.WARN)
        return
      end

      subcmd.handler()
    end,
    complete = function(param, cmd)
      local segments = vim.split(cmd, ' ')
      if #segments > 3 then
        return {}
      end

      return require('lib.cmd').get_matched(vim.tbl_keys(pack_lockfile_subcmds), ('^%s'):format(param))
    end,
  },
}

---Completion function for :Pack command
---@param param string Current param being typed
local function complete_pack_subcmd(param)
  local options = vim.tbl_keys(pack_subcmds)
  return require('lib.cmd').get_matched(options, ('^%s'):format(param))
end

---Completion function for :Pack command
---@param param string Current param being typed
---@param cmd string Full cmd string
---@param pos integer Cursor position
local function complete_pack_cmd(param, cmd, pos)
  local segments = vim.split(cmd, ' ', { plain = true })

  if #segments <= 2 then
    return complete_pack_subcmd(param)
  end

  local subcmd = pack_subcmds[segments[2]]
  if subcmd and subcmd.complete then
    return subcmd.complete(param, cmd, pos)
  end
end

---Command handler for Pack commands
---@param info vim.api.keyset.create_user_command.command_args
local function cmd(info)
  if #info.fargs == 0 then
    require('lib.pack.ui').open()
    return
  end

  -- vim.print(info.fargs)
  local sub = info.fargs[1]
  local subcmd = pack_subcmds[sub]
  if subcmd == nil then
    vim.notify(('[:Pack] unknown command "%s"'):format(subcmd), vim.log.levels.WARN)
    return
  end

  local rest = {}
  for i = 2, #info.fargs do
    rest[#rest + 1] = info.fargs[i]
  end

  local opts = { force = info.bang }
  return subcmd.handler(rest, opts)
end

return {
  pack_get_single_spec = pack_get_single_spec,
  pack_lockfile_subcmds = pack_lockfile_subcmds,
  pack_subcmds = pack_subcmds,
  complete = complete_pack_cmd,
  cmd = cmd,
}
