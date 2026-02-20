-- Filesystem related functions that deal with vscode remote path conversions

---Expand to the absolute path
---@param path string path to file
---@return string absolute path to the provided path
local function expand_path(path)
  local expanded = vim.fn.fnamemodify(path, ':p')
  if vim.fn.has('win32') == 1 then
    -- Get file, it will return matches if in vscode-remote extension
    local file, matches = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode, add prefix
      file = '//wsl.localhost/' .. file
    end

    file = vim.trim(file:gsub('\\', '/'))

    return file
  elseif vim.fn.has('wsl') == 1 then
    -- TODO: Pending for revision last regext segment
    local file, _ = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', ''):gsub('^[a-zA-Z]+/', '/')

    return file
  end

  return expanded
end

---Get the current file absolute path
---@param buf integer? bufnr to get its path
---@return string Path to the current file
local function get_file(buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)

  return expand_path(path)
end

---Get the directory containing a file
---@param path? string
local function get_path(path)
  -- Get directory of current buffer
  local expanded = path and vim.fn.fnamemodify(path, ':p:h') or vim.fn.expand('%:p:h')

  -- Remote file using windows nvim binary
  -- NOTE: The final `isdirectory` check will fail for
  -- wsl created symlinks even if the path is valid
  if vim.fn.has('win32') == 1 then
    -- Match a local file in windows filesystem but with wsl path e.g. "//wsl.localhost/<name>/mnt/"
    -- This assumes that the value after 'mnt/' is a drive letter
    local win_path, local_file_match = expanded:gsub('//wsl.localhost/[a-zA-Z]+/mnt/', '')
    if local_file_match > 0 then
      local segments = vim.split(win_path, '/')
      segments[1] = string.format('%s:', string.upper(segments[1])) -- make drive letter capital
      expanded = table.concat(segments, '/')
    end

    -- Get file, it will return matches if in vscode-remote extension
    local match, matches = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode, add prefix
      expanded = '//wsl.localhost/' .. match
    end
  -- Remote file using linux binary
  elseif vim.fn.has('wsl') == 1 then
    -- TODO: Pending for revision last regext segment
    local match, _ = expanded:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', ''):gsub('^[a-zA-Z]+/', '/')

    expanded = match
  end

  -- local buffpath = vim.fn.substitute(vim.trim(expanded), '\\', '/', 'g')
  local buffpath = vim.fs.normalize(vim.trim(expanded))

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
  local file_path = vim.trim(path or vim.fn.expand('%:p'))
  local real_dir = get_path(file_path)

  if not real_dir then
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
}
