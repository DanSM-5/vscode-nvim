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
local get_hunks = function (file)
  -- local dir = vim.fn.expand('%:p:h')

  local git_dir 
  if file then
    git_repo_cmd = { 'git', '-C', file, 'rev-parse', '--show-toplevel' }
  else
    git_repo_cmd = { 'git', 'rev-parse', '--show-toplevel' }
  end

  git_dir = vim.fn.substitute(vim.fn.system(git_repo_cmd), '[\r\n]', '', 'g')

  -- local git_dir = vim.fn.substitute(vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' }), '[\r\n]', '', 'g')
  -- local updated_cmd = string.format(hunk_command, git_dir, '')
  local updated_cmd = string.format(hunk_command, git_dir, file or '')
  local hunks_str = vim.fn.systemlist(updated_cmd)

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

local decodeURI
do
    local char, gsub, tonumber = string.char, string.gsub, tonumber
    local function _(hex) return char(tonumber(hex, 16)) end

    function decodeURI(s)
        s = gsub(s, '%%(%x%x)', _)
        return s
    end
end

-- print(decodeURI('%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82'))

local get_file = function ()
  if vim.fn.has('win32') then
    local file, matches = vim.fn.expand('%:p:h'):gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode
      file = '//wsl.localhost/' .. file
    end
    return file
  else
    return vim.fn.expand('%:p:h')
  end
end

local get_hunk_under_cursor = function (filename)
  local file = filename and filename or get_file()
  -- vim.print('file:'..file)
  local hunks = get_hunks(file)
  -- vim.print('Hunks:', hunks)

  for _, hunk in ipairs(hunks) do
    local hunk_under_cursor = is_cursor_in_hunk(hunk)
    if hunk_under_cursor then
      -- vim.print('Found:', hunk)
      return hunk
    end
  end
end

local get_hunks_vscode = function ()
  local file = get_file()
  return get_hunks(file)
end

local stage_hunk_under_cursor = function ()
  local vscode = require('vscode')
  local uri = vscode.eval('return vscode.window.activeTextEditor.document.uri.toString()')
  local hunk_under_cursor = require('utils.gitgutter').get_hunk_under_cursor()
  if not hunk_under_cursor then
    vim.print('no hunk')
    return
  end
  local line_change = {
    originalStartLineNumber = hunk_under_cursor[1],
    originalEndLineNumber = hunk_under_cursor[2],
    modifiedStartLineNumber = hunk_under_cursor[3],
    modifiedEndLineNumber = hunk_under_cursor[4],
  }
  -- local args = {
  --   uri = decodeURI(uri),
  --   changes = { line_change },
  --   index = 0,
  -- }
  local args = {
    uri,
    -- decodeURI(uri),
    { line_change },
    0,
  }
  vim.print('all:', args)
  vscode.action('git.stageChange', { args })
  require('vscode').action('git.stageChange', { uri = require('vscode').eval('return vscode.window.activeTextEditor.document.uri.toString()') })
end
return {
  is_cursor_in_hunk = is_cursor_in_hunk,
  get_hunks = get_hunks,
  get_hunk_under_cursor = get_hunk_under_cursor,
  get_file = get_file,
  stage_hunk_under_cursor = stage_hunk_under_cursor,
  get_hunks_vscode = get_hunks_vscode,
}

