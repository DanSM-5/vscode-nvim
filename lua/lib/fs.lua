-- Filesystem related functions that deal with vscode remote path conversions

local function query_default_distro()
  -- NOTE: in the future when the proposed `resolvers` api in vscode becomes
  -- available, it should be possible to fetch the distro name from vscode.
  --
  -- ```lua
  -- =require('vscode').eval(return vscode.env.remoteAuthority)
  -- ```
  -- 
  -- Ref: https://github.com/microsoft/vscode/blob/main/src/vscode-dts/vscode.proposed.resolvers.d.ts
  -- Ref: https://code.visualstudio.com/api/advanced-topics/using-proposed-api

  local command = {
    'powershell.exe',
    '-NoLogo',
    '-NonInteractive',
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
  }

  -- If on vscode, set window style to hidden
  if vim.g.vscode then
    table.insert(command, '-windowstyle')
    table.insert(command, 'hidden')
  end

  -- Add actual powershell command to run
  command = vim.list_extend(command, {
    '-Command',
    "((wsl --status)[0].Split(':')[1] -replace ([char]0), '').Trim()",
  })
  local default_distro = vim.system(command, { text = true }):wait().stdout
  return vim.trim(default_distro or '')
end

---Helper to transform windows paths e.g. C:/Windows/System32 into /mnt/c/Windows/System32
---@param path any
---@return string
local function win_to_wsl_path(path)
  local normalized = path:gsub('\\', '/')
  local segments = vim.split(normalized, ':', { plain = true, trimempty = true })
  return string.format(
    '/mnt/%s%s',
    segments[1]:lower(),
    segments[2]
  )
end

---Helper to transform wsl_paths to windows e.g. /mnt/c/Windows/System32 into C:/Windows/System32
---@param path string
---@return string
local function wsl_to_win_path(path)
  -- NOTE: use gsub instead of vim.fs.normalize
  -- because within wsl it won't change backslash to forwardslash
  local normalized = path:gsub('\\', '/')
  local rest, match_win_fs = normalized:gsub('/mnt/[a-z]', '')

  -- Case path is /mnt/c/something
  if match_win_fs > 0 then
    ---@type string
    local drive = normalized:match('/mnt/[a-z]')
    return string.format('%s:%s', drive:upper(), rest)
  end


  -- The below cases only work on windows.
  -- NOOP in other platforms
  local is_windows = vim.fn.has('win32') == 1 or vim.fn.has( 'wsl') == 1
  if not is_windows then
    return path
  end


  -- If inside wsl, nvim can access WSL_DISTRO_NAME to compose
  -- a valid windows path '/wsl.localhost/<distro>/path'
  if vim.fn.has('wsl') == 1 then
    return string.format(
      '//wsl.localhost/%s%s',
      -- os.getenv('WSL_DISTRO_NAME'),
      vim.env.WSL_DISTRO_NAME,
      normalized
    )
  end

  -- On windows with a wsl path. Similar to above but we assume default distro
  -- E.g. "/home/user" becomes "//wsl.localhost/<distro>/home/user" 
  local default_distro = query_default_distro()

  return string.format(
    '//wsl.localhost/%s%s',
    default_distro,
    normalized
  )
end

---Internal helper function to join part of a windows path
---@param partial string
local function partial_win_path_transform(partial)
  local segments = vim.split(partial, '/')
  segments[1] = string.format('%s:', string.upper(segments[1])) -- make drive letter capital
  return table.concat(segments, '/')
end


---Expand to the absolute path
---@param path string path to file
---@return string absolute path to the provided path
local function expand_path(path)
  local expanded = vim.trim(path)

  -- Remote file using windows nvim binary
  if vim.fn.has('win32') == 1 then
    -- Match a local file in windows filesystem but with wsl path e.g. "//wsl.localhost/<name>/mnt/"
    -- This assumes that the value after 'mnt/' is a drive letter
    local win_wsl_path_format, win_wsl_path_matches = expanded:gsub('//wsl.localhost/[a-zA-Z0-9%.%-]+/mnt/', '')
    if win_wsl_path_matches > 0 then
      expanded = partial_win_path_transform(win_wsl_path_format)
      return vim.trim(vim.fs.normalize(expanded))
    end


    -- Get file, it will return matches if in vscode-remote extension
    local remote_wsl_file, remote_wsl_matches = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    -- In case the matched is <distro>/mnt/<drive>/path/to/win/fs
    local without_mnt, mnt_matches = remote_wsl_file:gsub('^[a-zA-Z0-9%.%-]+/mnt/', '')
    if mnt_matches > 0 then
      expanded = partial_win_path_transform(without_mnt)
      return vim.trim(vim.fs.normalize(expanded))
    elseif remote_wsl_matches > 0 then
      -- in vscode, add prefix
      expanded = '//wsl.localhost/' .. remote_wsl_file
      return vim.trim(vim.fs.normalize(expanded))
    end


    -- WSL path to windows FS
    local wsl_path_to_windows, wsl_path_to_windows_matches = expanded:gsub('^/mnt/', '')
    if wsl_path_to_windows_matches > 0 then
      expanded = partial_win_path_transform(wsl_path_to_windows)
      return vim.trim(vim.fs.normalize(expanded))
    end

    -- WSL path
    local _, unix_path_matches = expanded:gsub('^/', '')
    if unix_path_matches > 0 then
      expanded = wsl_to_win_path(expanded)
    end

    -- expanded = vim.trim(expanded:gsub('\\', '/'))
    expanded = vim.trim(vim.fs.normalize(expanded))

    return expanded
  -- Remote file using linux binary
  elseif vim.fn.has('wsl') == 1 then

    -- TODO: Pending for revision last regexp segment
    local remote_wsl_file, _ = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', ''):gsub('^[a-zA-Z0-9%.%-]+/', '/')

    -- NOTE: use gsub instead of vim.fs.normalize
    -- because within wsl it won't change backslash to forwardslash
    return vim.trim(remote_wsl_file:gsub('\\', '/'))
  end

  expanded = vim.fn.fnamemodify(expanded, ':p')
  return vim.trim(vim.fs.normalize(expanded))
end

---Get the current file absolute path
---@param buf integer? bufnr to get its path
---@return string? Path to the current file
local function get_file(buf)
  local ok, path = pcall(vim.api.nvim_buf_get_name, buf or 0)

  if not ok then
    return
  end

  return expand_path(path)
end

---Get the directory containing a file
---@param path? string
local function get_path(path)
  -- Get directory of current buffer
  local expanded = path and vim.fn.fnamemodify(vim.trim(path), ':p:h') or vim.fn.expand('%:p:h')

  -- Remote file using windows nvim binary
  -- NOTE: The final `isdirectory` check will fail for
  -- wsl created symlinks even if the path is valid
  local buffpath = expand_path(expanded)

  -- vim.print('normalize:', buffpath)
  if vim.fn.isdirectory(buffpath) == 1 then
    return buffpath
  end
end

---Tries to get the path of a git repository or
---the path to the current file instead
---
---@param path? string Initial path to search for. If nil it will use the path of the current buffer
---@return string? Directory found of the git repository or directory containing the file
local function git_path(path)
  -- Directory holding the current file
  local cleaned_path = vim.trim(path or vim.fn.expand('%:p'))
  local expanded = expand_path(cleaned_path)

  local real_dir = vim.fn.isdirectory(expanded) == 1 and expanded or vim.fn.fnamemodify(expanded, ':p:h')

  if not real_dir or vim.fn.isdirectory(real_dir) == 0 then
    -- Cannot find directory containing file
    return
  end

  local gitcmd = string.format('git -C %s rev-parse --show-toplevel', vim.fn.shellescape(real_dir))
  local gitpath = vim.trim(vim.fn.system(gitcmd))

  if vim.fn.isdirectory(gitpath) == 1 then
    return vim.fs.normalize(gitpath)
  end

  return real_dir
end


return {
  expand_path = expand_path,
  get_file = get_file,
  get_path = get_path,
  git_path = git_path,
  win_to_wsl_path = win_to_wsl_path,
  wsl_to_win_path = wsl_to_win_path,
}
