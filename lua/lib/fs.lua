-- Filesystem related functions that deal with vscode remote path conversions

---Get the current file absolute path
---@param buf integer? bufnr to get its path
---@return string Path to the current file
local function get_file(buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)

  if vim.fn.has('win32') == 1 then
    -- Get file, it will return matches if in vscode-remote extension
    local file, matches = path:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode, add prefix
      file = '//wsl.localhost/' .. file
    end

    file = vim.trim(file:gsub('\\', '/'))

    return file
  elseif vim.fn.has('wsl') == 1 then
    -- TODO: Pending for revision last regext segment
    local file, _ = path:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', ''):gsub('^[a-zA-Z]+/', '/')

    return file
  end

  return path
end

---Tries to get the path of a git repository or
---the path to the current file instead
---
---@param path? string Initial path to search for. If nil it will use the path of the cuff buffer
---@return string? Directory found of the git repository or directory containing the file
local function git_path(path)
  -- Directory holding the current file
  local file_dir = vim.fs.normalize(vim.trim(path or vim.fn.expand('%:p:h')))

  local gitcmd = string.format('git -C %s rev-parse --show-toplevel', vim.fn.shellescape(file_dir))
  local gitpath = vim.trim(vim.fn.system(gitcmd))

  if vim.fn.isdirectory(gitpath) == 1 then
    return vim.fs.normalize(gitpath)
  end

  -- Get directory of current buffer
  local expanded = vim.fn.expand('%:p:h')

  -- Remote file using windows nvim binary
  if vim.fn.has('win32') == 1 then
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

  if vim.fn.isdirectory(buffpath) == 1 then
    return buffpath
  end
end


return {
  get_file = get_file,
  git_path = git_path,
}
