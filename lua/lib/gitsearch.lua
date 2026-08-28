local M = {}

local expected_keys = 'enter,ctrl-o,ctrl-e'
local supported_keys = {
  enter = true,
  ['ctrl-o'] = true,
  ['ctrl-e'] = true,
}

local function notify(message, level)
  vim.notify(('[GitSearch] %s'):format(message), level or vim.log.levels.ERROR)
end

---@param seed? string
---@return string?
local function git_root(seed)
  local buffer_path = seed and vim.fn.fnamemodify(vim.fn.expand(seed), ':p') or vim.api.nvim_buf_get_name(0)
  local directory = buffer_path == '' and vim.fn.getcwd()
    or (vim.fn.isdirectory(buffer_path) == 1 and buffer_path or vim.fn.fnamemodify(buffer_path, ':p:h'))
  if vim.fn.isdirectory(directory) == 0 then
    directory = vim.fn.getcwd()
  end

  local result = vim.system({ 'git', '-C', directory, 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 then
    notify('Not in a git repository', vim.log.levels.WARN)
    return nil
  end

  return vim.trim(result.stdout or '')
end

---@param name 'git-search-commits'|'git-file-history'
---@return string[]?
local function script_command(name)
  if vim.fn.has('win32') == 1 then
    local script = vim.fn.exepath(name .. '.ps1')
    if script ~= '' then
      local powershell = vim.fn.executable('pwsh') == 1 and 'pwsh'
        or (vim.fn.executable('powershell') == 1 and 'powershell' or nil)
      if not powershell then
        notify('Cannot find pwsh or powershell on PATH')
        return nil
      end
      return {
        powershell,
        '-NoLogo',
        '-NonInteractive',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script,
      }
    end
  end

  local executable = vim.fn.exepath(name)
  if executable == '' then
    notify(('Cannot find %s on PATH'):format(name))
    return nil
  end

  return { executable }
end

---@param root string
---@param path string
---@return string?
local function repository_path(root, path)
  local absolute = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(path), ':p'))
  local relative = vim.fs.relpath(root, absolute)
  if not relative then
    notify(('File is outside the repository: %s'):format(path))
    return nil
  end

  return relative
end

---@param root string
---@return string?
local function current_file(root)
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return nil
  end

  return repository_path(root, path)
end

---@param output string
---@return string[]
local function output_lines(output)
  local lines = vim.split(output, '\n', { plain = true })
  if lines[#lines] == '' then
    table.remove(lines)
  end
  return lines
end

---@param root string
---@param hashes string[]
---@param expected_key string
---@param origin_win integer
local function show_commits(root, hashes, expected_key, origin_win)
  local command = { 'git', '--no-pager', 'show', '--no-color' }
  vim.list_extend(command, hashes)

  vim.system(command, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = vim.trim(result.stderr or '')
        notify(message ~= '' and message or 'git show failed')
        return
      end

      local lines = output_lines(result.stdout or '')
      if #lines == 0 then
        return
      end

      local buffer = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buffer, ('gitsearch://commits/%d'):format(buffer))
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
      vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buffer })
      vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buffer })
      vim.api.nvim_set_option_value('swapfile', false, { buf = buffer })
      vim.api.nvim_set_option_value('filetype', 'git', { buf = buffer })
      vim.api.nvim_set_option_value('modifiable', false, { buf = buffer })
      vim.api.nvim_set_option_value('readonly', true, { buf = buffer })
      vim.api.nvim_set_option_value('modified', false, { buf = buffer })
      vim.api.nvim_buf_set_var(buffer, 'gitsearch_expected_key', expected_key)

      local window = vim.api.nvim_win_is_valid(origin_win) and origin_win or vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(window)
      vim.api.nvim_win_set_buf(window, buffer)
      vim.api.nvim_set_option_value('foldmethod', 'syntax', { win = window })
    end)
  end)
end

---@param lines string[]
---@return string?, string[]
local function parse_selection(lines)
  local key = nil
  local hashes = {}

  for _, line in ipairs(lines) do
    local value = vim.trim(line)
    if supported_keys[value] then
      key = value
      hashes = {}
    elseif key and value:match('^[0-9a-fA-F]+$') then
      table.insert(hashes, value)
    end
  end

  return key, hashes
end

---@param script 'git-search-commits'|'git-file-history'
---@param root string
---@param args string[]
---@param fullscreen boolean
local function run(script, root, args, fullscreen)
  local command = script_command(script)
  if not command then
    return
  end

  table.insert(command, '-Display')
  vim.list_extend(command, args)

  local origin_win = vim.api.nvim_get_current_win()
  local expect_env = script == 'git-search-commits' and 'GSC_EXPECT' or 'GFH_EXPECT'
  local env = {}
  env[expect_env] = expected_keys
  local options = {
    cmd = command,
    fullscreen = fullscreen,
    name = script,
    ft = 'gitsearch_terminal',
    term = {
      cwd = root,
      env = env,
    },
    on_term_exit = function(lines, status)
      local key, hashes = parse_selection(lines)
      if not key or #hashes == 0 then
        if status ~= 0 then
          notify(('%s exited with status %d'):format(script, status), vim.log.levels.WARN)
        end
        return
      end

      -- Enter preserves the original Vim integration, ctrl-o represents the
      -- script's printed patch output, and ctrl-e edits that same patch in the
      -- already-running editor. All three therefore resolve to a git buffer.
      show_commits(root, hashes, key, origin_win)
    end,
  }

  local terminal = require('lib.terminal')
  if fullscreen then
    terminal.win_term(options)
  else
    options.float = { border = 'none' }
    terminal.float_term(options)
  end
end

---@param args string[]
---@param fullscreen boolean
function M.search(args, fullscreen)
  local root = git_root()
  if not root then
    return
  end

  args = vim.list_slice(args)
  if #args == 1 and (args[1] == '%' or args[1] == '?') then
    local path = current_file(root)
    if not path then
      notify('The current buffer has no repository file', vim.log.levels.WARN)
      return
    end
    args = { '-File', path }
  end

  run('git-search-commits', root, args, fullscreen)
end

---@param file? string
---@param fullscreen boolean
function M.file_history(file, fullscreen)
  local root = git_root(file and file ~= '' and file ~= '%' and file ~= '?' and file or nil)
  if not root then
    return
  end

  local args = {}
  if file == '?' then
    -- Let git-file-history run its own file selector.
  elseif file and file ~= '' and file ~= '%' then
    local path = repository_path(root, file)
    if not path then
      return
    end
    args = { path }
  else
    local path = current_file(root)
    if path then
      args = { path }
    elseif file == '%' then
      notify('The current buffer has no repository file', vim.log.levels.WARN)
      return
    end
  end

  run('git-file-history', root, args, fullscreen)
end

return M
