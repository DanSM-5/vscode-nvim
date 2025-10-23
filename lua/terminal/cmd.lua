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
      path = require('utils.funcs').git_path()
    else
      path = args
    end
    local spec = vim.fn['fzf#vim#with_preview']()
    vim.list_extend(spec.options, vim.g.fzf_preview_options)
    vim.list_extend(spec.options, opts.bang and {
      '--preview-window', 'up,60%,wrap',
    } or { '--preview-window', 'right,60%,wrap' })
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
      '--preview-window', 'up,60%,wrap',
    } or { '--preview-window', 'right,60%,wrap' })
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
      '--preview-window', 'up,60%,wrap',
    } or { '--preview-window', 'right,60%,wrap' })
    local query = vim.fn.shellescape(table.concat(args.fargs or {}))
    local template = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    local command = string.format(template, query)

    -- Preview
    if vim.fn.has('win32') then
      vim.list_extend(spec.options, {
        '--with-shell', string.format(
          '%s -NoLogo -NonInteractive -NoProfile -Command',
          vim.fn.executable('pwsh') and 'pwsh' or 'powershell'
        ),
        '--preview', string.format('%s/preview.ps1 {}', vim.g.scripts_dir)
      })
    else
      vim.list_extend(spec.options, {
        '--preview', string.format('%s/preview.sh {}', vim.g.scripts_dir)
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

      local options = { 'incoming', 'outcoming' }
      local matched = vim.tbl_filter(function(option)
        local _, matches = string.gsub(option, '^' .. param, '')
        return matches > 0
      end, options)

      return #matched > 0 and matched or options
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
    end
  })
end

return {
  find_gitbash = find_gitbash,
  short_path = short_path,
  fzf_buffers = fzf_buffers,
  register = register,
}
