---Structured based from gitgutter where hunk is stored in a list
---[ baseStart, baseRange, newStart, newRange ]
---@alias Hunk { baseStart: integer, baseRange: integer, newStart: integer, newRange: integer } Represents a hunk from git cli

-- NOTE: Commands fail on windows when it meets the following conditions:
-- - vscode-neovim extension uses the `nvim` binary from windows
-- - vscode is working using the remote extension e.g. WSL
-- - awk binary from scoop (gawk package) is used (gitbash awk is not afected).
-- TODO: Rework commands in windows to use a different solution like powershell
-- or a binary that is reliable under the windows environment.
local unstaged_hunk_command = "git -C %s diff %s | awk '$0 ~ /^@@/ { print substr($2, 2)\",\"substr($3, 2) }'"
local staged_hunk_command = "git -C %s diff --cached %s | awk '$0 ~ /^@@/ { print substr($2, 2)\",\"substr($3, 2) }'"

---Splits a string by the given delimiter
---@param str string string to split
---@param delimiter string character(s) to use as split delimiter(s)
---@return string[] Array of strings
local function split(str, delimiter)
    local returnTable = {}
    for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        returnTable[#returnTable+1] = k
    end
    return returnTable
end

-- A line can be in 0 or 1 hunks, with the following exception: when the first
-- line(s) of a file has been deleted, and the new second line (and
-- optionally below) has been deleted, the new first line is in two hunks.
---Check if the cursor is currently on a hunk
---@param hunk Hunk Hunk to compare
---@return boolean Whether or not the cursor is under the provided hunk
local is_cursor_in_hunk = function (hunk)
  local current_line = vim.fn.line('.')

  if current_line == 1 and hunk.newStart == 0 then
    return true
  end

  if current_line >= hunk.newStart and current_line < hunk.newStart + (hunk.newRange == 0 and 1 or hunk.newRange) then
    return true
  end

  return false
end

-- //wsl.localhost/UbuntuDev/home/eduardo/projects/nbcu_main_mw
-- vscode-remote://wsl%2Bubuntudev/home/eduardo/projects/nbcu_main_mw

-- git vscode extension
-- https://github.com/microsoft/vscode/blob/main/extensions/git/src/commands.ts#L1724

-- local __file = debug.getinfo(1, "S").source:match("@(.*)$")
-- assert(__file ~= nil)
-- local bin_dir = fn.fnamemodify(__file, ":p:h:h")

-- Load package in path
     -- vim.print(package.path .. vim.fn.fnamemodify(debug.getinfo(1, "S").source:match("@(.*)$"), ':p:h') .. '\\lua\\utils\\?.lua;')
-- package.path = package.path .. vim.fn.fnamemodify(debug.getinfo(1, "S").source:match("@(.*)$"), ':p:h') .. '\\lua\\utils\\?.lua;'

---Get the hunks on the given directory or the current one if none is provided
---@param staged boolean|nil Whether to get the cached hunks or working area hunks
---@param dir string? Path to directory
---@return Hunk[]
local get_hunks = function (staged, dir)
  local hunks_cmd = staged and staged_hunk_command or unstaged_hunk_command

  local git_repo_cmd
  if dir then
    git_repo_cmd = { 'git', '-C', dir, 'rev-parse', '--show-toplevel' }
  else
    git_repo_cmd = { 'git', 'rev-parse', '--show-toplevel' }
  end

  -- vim.print('Repo:', git_repo_cmd)
  local git_dir = vim.fn.substitute(vim.fn.system(git_repo_cmd), '[\r\n]', '', 'g')

  -- local git_dir = vim.fn.substitute(vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' }), '[\r\n]', '', 'g')
  -- local updated_cmd = string.format(hunk_command, git_dir, '')
  local updated_cmd = string.format(hunks_cmd, git_dir, dir or '')
  -- vim.print('Cmd:', updated_cmd)
  local hunks_str = vim.fn.systemlist(updated_cmd)
  -- vim.print('Out:', hunks_str)

  ---@type Hunk[]
  local hunks = {}

  for _, hunkstr in ipairs(hunks_str) do
    ---@type [string, string, string, string]
    local rawHunk = split(hunkstr, ',')
    ---@type Hunk
    local hunk = {
      baseStart = vim.fn.str2nr(rawHunk[1], 10),
      baseRange = vim.fn.str2nr(rawHunk[2], 10),
      newStart = vim.fn.str2nr(rawHunk[3], 10),
      newRange = vim.fn.str2nr(rawHunk[4], 10),
    }

    table.insert(hunks, hunk)
  end

  return hunks
end

---Get the current file absolute path
---@return string Path to the current file
local get_file = function ()
  if vim.fn.has('win32') then
    -- Get file, it will return matches if in vscode-remote extension
    local file, matches = vim.fn.expand('%:p'):gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode, add prefix
      file = '//wsl.localhost/' .. file
    end
    return file
  else
    return vim.fn.expand('%:p')
  end
end

---Get the current hunk under the cursor
---@param staged? boolean Whether or not get the staged hunks
---@return Hunk? The hunk under the cursor or nil if non is found
local get_hunk_under_cursor = function (staged)
  local file = get_file()
  -- We need a filename for get_hunks
  local dir = vim.fn.fnamemodify(file, ':p:h')

  local hunks = get_hunks(staged, dir)

  for _, hunk in ipairs(hunks) do
    local hunk_under_cursor = is_cursor_in_hunk(hunk)
    if hunk_under_cursor then
      return hunk
    end
  end
end

local stage_hunk_under_cursor_vscode = function ()
  -- local file = get_file()
  -- return get_hunks(file)

  local hunk = get_hunk_under_cursor()
  if not hunk then
    return
  end

  -- NOTE: Left this here for later
  -- Ref: https://vi.stackexchange.com/questions/20066/is-it-possible-to-perform-a-visual-block-selection-programmatically-using-line-a
  -- vim.cmd.normal(hunk.newStart..'G|V'..(hunk.newStart + hunk.newRange)..'G|')

  require('vscode')
    .action('git.stageSelectedRanges', {
      range = { hunk.newStart, hunk.newStart + hunk.newRange },
      restore_selection = true,
    })
end

local unstage_hunk_under_cursor_vscode = function ()
  local hunk = get_hunk_under_cursor(true)
  if not hunk then
    return
  end

  require('vscode')
    .action('git.unstageSelectedRanges', {
      range = { hunk.newStart, hunk.newStart + hunk.newRange },
      restore_selection = true,
    })
end

local revert_hunk_under_cursor_vscode = function ()
  local hunk = get_hunk_under_cursor()
  if not hunk then
    return
  end

  require('vscode')
    .action('git.revertSelectedRanges', {
      range = { hunk.newStart, hunk.newStart + hunk.newRange },
      restore_selection = false,
    })
end

---Revert all changes in the file using the git cli
local revert_all_changes = function ()
  local file = get_file()
  local dir = vim.fn.fnamemodify(file, ':p:h')
  local git_repo_cmd = { 'git', '-C', dir, 'rev-parse', '--show-toplevel' }
  local git_dir = vim.fn.substitute(vim.fn.system(git_repo_cmd), '[\r\n]', '', 'g')
  local git_cmd = { 'git', '-C', git_dir, 'checkout', '--', file }
  vim.fn.system(git_cmd)
end

local stage_hunk_under_cursor = function ()
  -- NOTE: Calling `git.stageChange` do not work
  -- local uri = vscode.eval('return vscode.window.activeTextEditor.document.uri.toString()')
  -- local line_change = {
  --   originalStartLineNumber = hunk_under_cursor[1],
  --   originalEndLineNumber = hunk_under_cursor[1] + hunk_under_cursor[2] - 1,
  --   modifiedStartLineNumber = hunk_under_cursor[3],
  --   modifiedEndLineNumber = hunk_under_cursor[3] + hunk_under_cursor[4] - 1,
  -- }
  -- local args = {
  --   uri = decodeURI(uri),
  --   changes = { line_change },
  --   index = 0,
  -- }
  -- vscode.action('git.stageChange', args)

  if vim.g.vscode then
    stage_hunk_under_cursor_vscode()
  end
end

local unstage_hunk_under_cursor = function ()
  if vim.g.vscode then
    unstage_hunk_under_cursor_vscode()
  end
end

local revert_hunk_under_cursor = function ()
  if vim.g.vscode then
    revert_hunk_under_cursor_vscode()
  end
end

return {
  is_cursor_in_hunk = is_cursor_in_hunk,
  get_hunks = get_hunks,
  get_hunk_under_cursor = get_hunk_under_cursor,
  get_file = get_file,
  stage_hunk_under_cursor = stage_hunk_under_cursor,
  stage_hunk_under_cursor_vscode = stage_hunk_under_cursor_vscode,
  unstage_hunk_under_cursor = unstage_hunk_under_cursor,
  unstage_hunk_under_cursor_vscode = unstage_hunk_under_cursor_vscode,
  revert_hunk_under_cursor = revert_hunk_under_cursor,
  revert_hunk_under_cursor_vscode = revert_hunk_under_cursor_vscode,
  revert_all_changes = revert_all_changes,
}

