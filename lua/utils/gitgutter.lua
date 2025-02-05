local hunk_command = "git -C %s diff %s | awk '$0 ~ /^@@/ { print substr($2, 2)\",\"substr($3, 2) }'"

local function split(str, delimiter)
    local returnTable = {}
    for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)")
    do
        returnTable[#returnTable+1] = k
    end
    return returnTable
end

-- A line can be in 0 or 1 hunks, with the following exception: when the first
-- line(s) of a file has been deleted, and the new second line (and
-- optionally below) has been deleted, the new first line is in two hunks.
local is_cursor_in_hunk = function (hunk)
  local current_line = vim.fn.line('.')

  if current_line == 1 and hunk[3] == 0 then
    return true
  end

  if current_line >= hunk[3] and current_line < hunk[3] + (hunk[4] == 0 and 1 or hunk[4]) then
    return true
  end

  return false
end

-- git vscode extension
-- https://github.com/microsoft/vscode/blob/main/extensions/git/src/commands.ts#L1724

-- local __file = debug.getinfo(1, "S").source:match("@(.*)$")
-- assert(__file ~= nil)
-- local bin_dir = fn.fnamemodify(__file, ":p:h:h")

-- Load package in path
     -- vim.print(package.path .. vim.fn.fnamemodify(debug.getinfo(1, "S").source:match("@(.*)$"), ':p:h') .. '\\lua\\utils\\?.lua;')
-- package.path = package.path .. vim.fn.fnamemodify(debug.getinfo(1, "S").source:match("@(.*)$"), ':p:h') .. '\\lua\\utils\\?.lua;'
local get_hunks = function (file)
  -- local dir = vim.fn.expand('%:p:h')

  local git_dir = vim.fn.substitute(vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' }), '[\r\n]', '', 'g')
  hunk_command = string.format(hunk_command, git_dir, file or '')
  vim.print(hunk_command)
  local hunks_str = vim.fn.systemlist(hunk_command)

  local hunks = {}

  for _, hunkstr in ipairs(hunks_str) do
    local rawHunk = split(hunkstr, ',')
    local hunk = {}

    for _, hunkVal in ipairs(rawHunk) do
      table.insert(hunk, vim.fn.str2nr(hunkVal, 10))
    end

    table.insert(hunks, hunk)
  end

  return hunks
end

local get_hunk_under_cursor = function ()
  local file = vim.fn.expand('%:p')
  local hunks = get_hunks(file)

  for _, hunk in ipairs(hunks) do
    local hunk_under_cursor = is_cursor_in_hunk(hunk)
    if hunk_under_cursor then
      return hunk
    end
  end

end

return {
  is_cursor_in_hunk = is_cursor_in_hunk,
  get_hunks = get_hunks,
  get_hunk_under_cursor = get_hunk_under_cursor,
}

