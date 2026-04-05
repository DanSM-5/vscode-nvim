-- Get this script file path
local __file = vim.fn.substitute(debug.getinfo(1, 'S').source:match('@(.*)$'), '\\', '/', 'g')

local short_path = function(path)
  local shorted = vim.fn.system('for %A in ("' .. path .. '") do @echo %~sA')
  local cleaned = shorted:gsub('\n', '')
  return vim.fn.substitute(cleaned, '\\', '/', 'g')
end

local find_gitbash = function()
  local candidates = vim.fn.systemlist({ 'where.exe', 'bash' })
  local found = vim.tbl_filter(function(value)
    local _, matches = value:gsub('[Gg]it', '')
    return matches > 0
  end, candidates)[1]

  if found == nil then
    return
  end

  return short_path(found)
end

---@param query string Query for initial search
---@param fullscreen boolean Whether or not to display in fullscreen
local fzf_buffers = function(query, fullscreen)
  local remove_list = vim.fn.substitute(vim.fn.tempname(), '\\', '/', 'g')

  local repo_root = vim.fn.fnamemodify(vim.fs.find('.git', { upward = true, path = __file })[1], ':h')
  local remove_command = ''

  if vim.fn.has('win32') == 1 then
    local gitbash = find_gitbash()

    if gitbash == nil then
      vim.notify('Cannot find gitbash', vim.log.levels.ERROR)
      return
    end

    local drive_letter = repo_root:sub(1, 1):lower()
    local gitbash_repo = '/' .. drive_letter .. repo_root:gsub('^[A-Za-z]:', '')
    remove_command = gitbash .. ' ' .. gitbash_repo .. '/bin/remove_buff.sh'
  else
    local bin_path = repo_root .. '/bin'
    remove_command = bin_path .. '/remove_buff.sh'
  end

  remove_command = remove_command .. ' {3} "' .. remove_list .. '"'

  local spec = vim.fn['fzf#vim#with_preview']({
    placeholder = '{1}',
    options = {
      '--cycle',
      '--no-multi',
      '--ansi',
      '--input-border=rounded',
      '--bind',
      'ctrl-l:change-preview-window(down|hidden|)',
      '--bind',
      'ctrl-/:change-preview-window(down|hidden|)',
      '--bind',
      'alt-up:preview-page-up,alt-down:preview-page-down',
      '--bind',
      'shift-up:preview-up,shift-down:preview-down',
      '--bind',
      'ctrl-^:toggle-preview,ctrl-s:toggle-sort',
      '--bind',
      'alt-c:clear-query,alt-f:first,alt-l:last,alt-a:select-all,alt-d:deselect-all',
      '--bind',
      'ctrl-q:execute-silent(' .. remove_command .. ')+exclude+bell',
    },
    exit = function()
      ---@diagnostic disable-next-line
      if not (vim.uv or vim.loop).fs_stat(remove_list) then
        return
      end

      local buffers = vim.fn.readfile(remove_list) --[[@as string[] ]]
      if #buffers == 0 then
        return
      end

      pcall(vim.fn.delete, remove_list)

      for _, buffer in ipairs(buffers) do
        local bufnr = tonumber(buffer)
        if vim.fn.bufloaded(bufnr) then
          vim.cmd('bd! ' .. buffer)
        end
      end
    end,
  })

  vim.fn['fzf#vim#buffers'](query or '', spec, fullscreen and 1 or 0)
end

local register = function()
  vim.api.nvim_create_user_command('Buffers', function(opts)
    fzf_buffers(opts.fargs[1], opts.bang)
  end, {
    desc = '[fzf] Buffers with the ability to close selected buffers with ctrl+q',
    bang = true,
    complete = 'buffer',
    bar = true,
    nargs = '?',
  })

  -- Configure terminal buffers
  vim.api.nvim_create_user_command('Term', function(opts)
    if opts.bang then
      vim.cmd.tabnew()
    end
    vim.cmd.terminal()
  end, {
    bang = true,
    bar = true,
    desc = '[Terminal] Open terminal',
  })
  vim.api.nvim_create_user_command('Vterm', function(_)
    vim.cmd.vsplit()
    vim.cmd.terminal()
  end, {
    bang = true,
    bar = true,
    desc = '[Terminal] Open terminal',
  })
  vim.api.nvim_create_user_command('Sterm', function(_)
    vim.cmd.split()
    vim.cmd.terminal()
  end, {
    bang = true,
    bar = true,
    desc = '[Terminal] Open terminal',
  })

  vim.api.nvim_create_user_command('GitFZF', function(opts)
    local args = vim.fn.join(opts.fargs)
    local bang = opts.bang and 1 or 0
    local path = '' ---@type string?
    if vim.fn.empty(args) == 1 then
      path = require('lib.fs').git_path()
    else
      path = args
    end
    local spec = vim.fn['fzf#vim#with_preview']()
    vim.list_extend(spec.options, vim.g.fzf_preview_options)
    vim.list_extend(spec.options, opts.bang and {
      '--preview-window',
      'up,60%,wrap-word',
    } or { '--preview-window', 'right,60%,wrap-word' })
    vim.fn['fzf#vim#files'](path, spec, bang)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '?',
    complete = 'dir',
    desc = '[Git] Open fzf in top git repo or active buffer directory',
  })

  vim.api.nvim_create_user_command('FzfFiles', function(args)
    local query = table.concat(args.fargs or {}, ' ')
    local spec = vim.fn['fzf#vim#with_preview']()
    vim.list_extend(spec.options, vim.g.fzf_preview_options)
    vim.list_extend(spec.options, args.bang and {
      '--preview-window',
      'up,60%,wrap-word',
    } or { '--preview-window', 'right,60%,wrap-word' })
    vim.fn['fzf#vim#files'](query, spec, args.bang and 1 or 0)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '?',
    complete = 'dir',
    desc = '[Fzf] Use fzf to select a file',
  })

  vim.api.nvim_create_user_command('Helptags', function(args)
    require('lib.fzf').helptags(args.bang)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '?',
    complete = 'dir',
    desc = '[Fzf] Display helptags',
  })

  vim.api.nvim_create_user_command('RG', function(args)
    ---@type fzf.rg.args
    local opts = {
      query = table.concat(args.fargs or {}),
      fullscreen = args.bang,
    }

    require('lib.fzf').fzf_rg(opts)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '*',
    desc = '[Fzf] RG function',
  })

  vim.api.nvim_create_user_command('Rg', function(args)
    local spec = { options = {} }
    vim.list_extend(spec.options, vim.g.fzf_preview_options)
    vim.list_extend(spec.options, args.bang and {
      '--preview-window',
      'up,60%,wrap-word',
    } or { '--preview-window', 'right,60%,wrap-word' })
    local query = vim.fn.shellescape(table.concat(args.fargs or {}))
    local template = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    local command = string.format(template, query)

    -- Preview
    if vim.fn.has('win32') then
      vim.list_extend(spec.options, {
        '--with-shell',
        string.format(
          '%s -NoLogo -NonInteractive -NoProfile -Command',
          vim.fn.executable('pwsh') and 'pwsh' or 'powershell'
        ),
        '--preview',
        string.format('%s/preview.ps1 {}', vim.g.scripts_dir),
      })
    else
      vim.list_extend(spec.options, {
        '--preview',
        string.format('%s/preview.sh {}', vim.g.scripts_dir),
      })
    end

    vim.fn['fzf#vim#grep'](command, spec, args.bang and 1 or 0)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '*',
    desc = '[Fzf] Rg function',
  })

  vim.api.nvim_create_user_command('Redir', function(ctx)
    -- local lines = vim.split(vim.api.nvim_exec(ctx.args, true), '\n', { plain = true })
    local lines = vim.split(vim.api.nvim_exec2(ctx.args, { output = true }).output or '', '\n', { plain = true })
    vim.cmd('new')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
  end, { nargs = '+', complete = 'command' })

  -- Override regular LF autocommand
  ---Create LF command to use lf binary to select files
  vim.api.nvim_create_user_command('LF', function(opts)
    require('lib.lf').lf(opts.fargs[1], opts.bang)
  end, { force = true, bar = true, nargs = '?', complete = 'dir', bang = true })

  vim.api.nvim_create_user_command('FunctionReferences', function(cmd_opts)
    local Hierarchy = require('lib.hierarchy')
    local depth = Hierarchy.depth
    local direction = 'outcoming'
    if cmd_opts.args and cmd_opts.args ~= '' then
      local args = vim.split(cmd_opts.args, ' ')
      direction = args[1] and args[1]:lower()
      depth = tonumber(args[2]) or Hierarchy.depth
    end

    Hierarchy.find_recursive_calls(direction, depth)
  end, {
    nargs = '?',
    desc = '[Hierarchy] Find function references recursively. Usage: FunctionReferences [incoming|outcoming] [depth]',
    complete = function(param, cmd)
      if #vim.split(cmd, ' ') > 2 then
        return
      end

      return require('lib.cmd').get_matched({ 'incoming', 'outcoming' }, string.format('^%s', param))
    end,
  })

  vim.api.nvim_create_user_command('Todos', function(args)
    require('lib.fzf').todos(args.fargs, args.bang)
  end, {
    bang = true,
    bar = true,
    force = true,
    nargs = '*',
    desc = '[Fzf] Find todos',
    complete = function(current)
      return require('lib.fzf').todos_complete(current)
    end,
  })

  -- Recreate removed lsp commands
  if vim.fn.has('nvim-0.12.0') == 1 then
    ---@type table<string, { handler: fun() } | nil>
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
    }

    ---Completion function for :Lsp command
    ---@param param string Current param being typed
    ---@param cmd string Full cmd string
    local function complete_lsp_cmd(param, cmd)
      local segments = vim.split(cmd, ' ', { plain = true })

      if #segments == 2 then
        return require('lib.cmd').get_matched(vim.tbl_keys(lsp_subcmds), param)
      end

      return {}
    end

    vim.api.nvim_create_user_command('Lsp', function(info)
      local sub = info.fargs[1]
      local subcmd = lsp_subcmds[sub]

      if subcmd == nil then
        vim.notify(('[:Lsp] unknown subcmd "%s"'):format(sub))
        return
      end

      subcmd.handler()
    end, {
      desc = '[:Lsp] missing options from `:lsp` command',
      nargs = 1,
      bang = true,
      bar = true,
      force = true,
      complete = complete_lsp_cmd,
    })

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

      return require('lib.pack').complete_packages(arg_lead)
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
            return require('lib.pack').update(plugins, opts)
          end

          -- update all if forced
          if opts.force then
            -- require('lib.pack').update(plugins, { force = true })
            return require('lib.pack').update(plugins, opts)
          end

          -- otherwise confirm first
          local prompt = 'Do you want to update ALL packages?'
          local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)

          if choice == 1 then
            vim.notify('[:Pack] Updating everything.', vim.log.levels.INFO)
            return require('lib.pack').update(nil, opts)
          else
            vim.notify('Update aborted.', vim.log.levels.WARN)
          end
        end,
        complete = function(...)
          return require('lib.pack').complete_packages(...)
        end,
      },
      install = {
        handler = function(plugins)
          return require('lib.pack').install(plugins)
        end,
      },
      delete = {
        handler = function(...)
          return require('lib.pack').delete(...)
        end,
        complete = function(...)
          return require('lib.pack').complete_packages(...)
        end,
      },
      explore = {
        handler = function (plugins)
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
            term = { cwd = spec.path }
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
          local lib_pack = require('lib.pack').load_tbl[single]

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
            return require('lib.pack').restore()
          end

          -- otherwise confirm first
          local prompt = 'Do you want to restore ALL packages?'
          local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)

          if choice == 1 then
            vim.notify('[:Pack] Restoring to current lockfile values.', vim.log.levels.INFO)
            return require('lib.pack').restore()
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

    vim.api.nvim_create_user_command('Pack', function(info)
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
    end, {
      desc = '[Pack] Helpers for using vim.pack',
      nargs = '*',
      bang = true,
      bar = true,
      force = true,
      complete = complete_pack_cmd,
    })
  end
end

return {
  find_gitbash = find_gitbash,
  short_path = short_path,
  fzf_buffers = fzf_buffers,
  register = register,
}
