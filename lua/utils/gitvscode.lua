---@module 'types.vscode'

---Structured based from gitgutter where hunk is stored in a list
---[ baseStart, baseRange, newStart, newRange ]
---@alias Hunk { baseStart: integer, baseRange: integer, newStart: integer, newRange: integer } Represents a hunk from git cli

--- VsCodeHunkKind
--- [1] 1 Added
--- [2] 2 Deleted
--- [3] 3 Modified

---@class VsCodeHunkRange
---@field startLineNumber integer Starting of the hunk
---@field endLineNumberExclusive integer End of hunk exclusive

---@class VsCodeHunk
---@field original VsCodeHunkRange Range of the original file
---@field modified VsCodeHunkRange Range of the modified file
---@field kind 1|2|3 Kind value. See VsCodeHunkKind


-- NOTE: Commands fail on windows when it meets the following conditions:
-- - vscode-neovim extension uses the `nvim` binary from windows
-- - vscode is working using the remote extension e.g. WSL
-- - awk binary from scoop (gawk package) is used (gitbash awk is not afected).
-- TODO: Rework commands in windows to use a different solution like powershell
-- or a binary that is reliable under the windows environment.
-- There are still limitations like the need to allow git to work on directories with
-- different permissions (trusts directories).
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

-- TODO: Check vscode.window.activeTextEditor.diffInformation
-- Sample:
-- local a = {
--   {
--     changes = { {
--         kind = 1,
--         modified = {
--           endLineNumberExclusive = 491,
--           startLineNumber = 490
--         },
--         original = {
--           endLineNumberExclusive = 490,
--           startLineNumber = 490
--         }
--       } },
--     documentVersion = 201,
--     isStale = false,
--     modified = {
--       ["$mid"] = 1,
--       _sep = 1,
--       external = "file:///c%3A/Users/daniel/projects/tabs-to-links/action/script.js",
--       fsPath = "c:\\Users\\daniel\\projects\\tabs-to-links\\action\\script.js",
--       path = "/c:/Users/daniel/projects/tabs-to-links/action/script.js",
--       scheme = "file"
--     },
--     original = {
--       ["$mid"] = 1,
--       external = "git:/c%3A/Users/daniel/projects/tabs-to-links/action/script.js.git?%7B%22path%22%3A%22c%3A%5C%5CUsers%5C%5Cdaniel%5C%5Cprojects%5C%5Ctabs-to-links%5C%5Caction%5C%5Cscript.js%22%2C%22ref%22%3A%22%22%7D",
--       path = "/c:/Users/daniel/projects/tabs-to-links/action/script.js.git",
--       query = '{"path":"c:\\\\Users\\\\daniel\\\\projects\\\\tabs-to-links\\\\action\\\\script.js","ref":""}',
--       scheme = "git"
--     }
--   }
-- }


---Register namespace that holds required functions in vscode
local registerGit = function ()

  require('vscode').eval([[
    if (globalThis._vscode_git) return;

    globalThis._vscode_git = {
      get_line: () => {
        const line = vscode.window.activeTextEditor?.selection?.active?.line ||
          vscode.window.activeTextEditor?.selection?.start?.line;

        // Lines in vscode are 0-based index, so increate by 1
        if (line != null) { return line + 1; }
      },
      apply_command: (opts) => {
        try {
          const { command } = opts;

          // Need command
          if (!command) { return false; }

          const line = opts?.line == null ? globalThis._vscode_git.get_line() : opts.line;

          if (line == null) {
            return false;
          }

          // Ref for comparing against query
          // Empty string for unstaged hunks
          // or 'HEAD' for all hunks.
          const ref = opts?.ref == null ? '' : opts.ref;
          const editor = vscode.window.activeTextEditor;

          // Get changes from editor
          const changes = editor.diffInformation.find(di => {
            const query = JSON.parse(di.original.query);
            return query.ref === ref;
          })?.changes ||
            editor.diffInformation[0].changes ||
            editor.diffInformation[1].changes;

          // Find hunk under the cursor (if any)
          const hunk = changes.find(h => {
            return h.modified.startLineNumber <= line && h.modified.endLineNumberExclusive >= line;
          });

          if (!hunk || !editor) {
            logger.info(`Unable to process ${command}. Hunk or editor missing`);
            return false;
          }

          logger.info('Found hunk:', hunk);

          // logger.info('selection: ', selection);
          // logger.info('opts', opts);

          // Create new selection
          const modified = hunk.modified;
          const range = new vscode.Range(
            new vscode.Position(modified.startLineNumber - 1, 0),
            new vscode.Position(modified.endLineNumberExclusive - 1, 0)
          );
          const selection = new vscode.Selection(range.start, range.end);

          // Save current to restore after command
          const prevSelection = editor.selection;

          // Set selection and call command
          editor.selection = selection;
          vscode.commands.executeCommand(command);

          // Recover selection
          editor.selection = prevSelection;

          // Return true if nothing throw an error
          return true;
        } catch (e) {
          // If anything fails, consider it as false
          return false;
        }
      },
    };
  ]])
end

---Apply a git command directly on vscode
---@param opts { command: 'git.stageSelectedRanges'|'git.unstageSelectedRanges'|'git.revertSelectedRanges'; ref?: ''|'HEAD'; line?: integer }
---@return boolean If the command succeeded
local apply_command_vscode = function (opts)
  opts = opts or {}

  -- vscode hunk lines are 1-based indexed
  -- local line = vim.fn.line('.')

  -- Try to get the overlaping line in the hunk from diffInformation

  ---@type boolean
  local success = require('vscode').eval([[
    globalThis?._vscode_git?.apply_command?.(args);
  ]], {
      args = {
        line = opts.line,
        command = opts.command,
        ref = opts.ref,
      }
    })

  return success

  -- return {
  --   newStart = vsc_hunk.modified.startLineNumber,
  --   newRange = vsc_hunk.modified.endLineNumberExclusive - vsc_hunk.modified.startLineNumber,
  --   baseStart = vsc_hunk.original.startLineNumber,
  --   baseRange = vsc_hunk.original.endLineNumberExclusive - vsc_hunk.original.startLineNumber,
  -- }
end

---Get the unstaged hunk from vscode
---This is identified as the one with query without ref
---@return VsCodeHunk? Hunk if available
local get_unstaged_hunk_under_cursor_js = function ()
  -- vscode hunk lines are 1-based indexed
  local line = vim.fn.line('.')

  -- Try to get the overlaping line in the hunk from diffInformation

  ---@type VsCodeHunk?
  local vsc_hunk = require('vscode').eval([[
    const changes = vscode.window?.activeTextEditor?.diffInformation?.find(di => {
      const query = JSON.parse(di.original.query)
      return query.ref === ''
    })?.changes ||
      vscode.window?.activeTextEditor?.diffInformation?.[0]?.changes ||
      vscode.window?.activeTextEditor?.diffInformation?.[1]?.changes

    const hunk = changes?.find(h => {
      return h.modified.startLineNumber <= args.line && h.modified.endLineNumberExclusive >= args.line
    })

    logger.info('Found hunk:', hunk)

    return hunk
  ]], { args = { line = line } })

  -- We don't want to return vim.NIL but lua's nil
  if vsc_hunk == vim.NIL or not vsc_hunk then
    return
  end

  return vsc_hunk

  -- return {
  --   newStart = vsc_hunk.modified.startLineNumber,
  --   newRange = vsc_hunk.modified.endLineNumberExclusive - vsc_hunk.modified.startLineNumber,
  --   baseStart = vsc_hunk.original.startLineNumber,
  --   baseRange = vsc_hunk.original.endLineNumberExclusive - vsc_hunk.original.startLineNumber,
  -- }
end

---Get the hunk from vscode
---This function checks for diffInformation\[1] preferably, if not present,
---tries diffInformation\[0].
---@return VsCodeHunk? Hunk if available
local get_hunk_under_cursor_js = function ()
  -- vscode hunk lines are 1-based indexed
  local line = vim.fn.line('.')

  -- Try to get the overlaping line in the hunk from diffInformation

  ---@type VsCodeHunk?
  local vsc_hunk = require('vscode').eval([[
    const changes = vscode.window?.activeTextEditor?.diffInformation?.find(di => {
      const query = JSON.parse(di.original.query)
      return query.ref === 'HEAD'
    })?.changes ||
      vscode.window?.activeTextEditor?.diffInformation?.[1]?.changes ||
      vscode.window?.activeTextEditor?.diffInformation?.[0]?.changes

    const hunk = changes?.find(h => {
      return h.modified.startLineNumber <= args.line && h.modified.endLineNumberExclusive >= args.line
    })

    logger.info('Found hunk:', hunk)

    return hunk
  ]], { args = { line = line } })

  -- We don't want to return vim.NIL but lua's nil
  if vsc_hunk == vim.NIL or not vsc_hunk then
    return
  end

  return vsc_hunk
end

-- VSCode documentation
-- https://vscode-api.js.org/classes/vscode.Diagnostic.html

-- //wsl.localhost/UbuntuDev/home/eduardo/projects/project
-- vscode-remote://wsl%2Bubuntudev/home/eduardo/projects/project

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
---@param bur integer? bufnr to get its path
---@return string Path to the current file
local get_file = function (buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)

  if vim.fn.has('win32') then
    -- Get file, it will return matches if in vscode-remote extension
    local file, matches = path:gsub('%%2B', '.'):gsub('vscode%-remote://wsl%.', '')
    if matches > 0 then
      -- in vscode, add prefix
      file = '//wsl.localhost/' .. file
    end

    file = vim.trim(file:gsub('\\', '/'))

    return file
  end

  return path
end

---Get the current hunk under the cursor
---@param staged? boolean Whether or not get the staged hunks
---@return Hunk? The hunk under the cursor or nil if non is found
local get_hunk_under_cursor_cli = function (staged)
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

-- NOTE: First try extracting hunk from vscdoe, then fallback to git cli
-- Hunk info from vscode is faster and more accurate
-- Unstage hunks seems not to be possible from the regular editor and seems to be more
-- of a feature of some diff view.

local stage_hunk_under_cursor_vscode = function ()
  apply_command_vscode({
    command = 'git.stageSelectedRanges',
    ref = '',
  })

  -- local vscode_hunk = get_unstaged_hunk_under_cursor_js()
  -- if vscode_hunk then
  --   require('vscode')
  --     .action('git.stageSelectedRanges', {
  --       range = { vscode_hunk.modified.startLineNumber - 1, vscode_hunk.modified.endLineNumberExclusive - 1 },
  --       restore_selection = true,
  --     })
  --   return
  -- end

  -- local hunk = get_hunk_under_cursor_cli()
  -- if not hunk then
  --   return
  -- end

  -- NOTE: Left this here for later
  -- Ref: https://vi.stackexchange.com/questions/20066/is-it-possible-to-perform-a-visual-block-selection-programmatically-using-line-a
  -- vim.cmd.normal(hunk.newStart..'G|V'..(hunk.newStart + hunk.newRange)..'G|')

  -- require('vscode')
  --   .action('git.stageSelectedRanges', {
  --     range = { hunk.newStart - 1, hunk.newStart - 1 + hunk.newRange },
  --     restore_selection = true,
  --   })
end

local unstage_hunk_under_cursor_vscode = function ()
  apply_command_vscode({
    command = 'git.unstageSelectedRanges',
    ref = 'HEAD',
  })

  -- local vscode_hunk = get_hunk_under_cursor_js()
  -- if vscode_hunk then
  --   require('vscode')
  --     .action('git.unstageSelectedRanges', {
  --       range = { vscode_hunk.modified.startLineNumber - 1, vscode_hunk.modified.endLineNumberExclusive - 1 },
  --       restore_selection = true,
  --     })
  --   return
  -- end

  -- local hunk = get_hunk_under_cursor_cli(true)
  -- if not hunk then
  --   return
  -- end

  -- require('vscode')
  --   .action('git.unstageSelectedRanges', {
  --     range = { hunk.newStart - 1, hunk.newStart - 1 + hunk.newRange },
  --     restore_selection = true,
  --   })
end

local revert_hunk_under_cursor_vscode = function ()
  apply_command_vscode({
    command = 'git.revertSelectedRanges',
    ref = '',
  })

  -- local vscode_hunk = get_unstaged_hunk_under_cursor_js()
  -- if vscode_hunk then
  --   require('vscode')
  --     .action('git.revertSelectedRanges', {
  --       range = { vscode_hunk.modified.startLineNumber - 1, vscode_hunk.modified.endLineNumberExclusive - 1 },
  --       restore_selection = true,
  --     })
  --   return
  -- end

  -- local hunk = get_hunk_under_cursor_cli()
  -- if not hunk then
  --   return
  -- end

  -- require('vscode')
  --   .action('git.revertSelectedRanges', {
  --     range = { hunk.newStart - 1, hunk.newStart - 1 + hunk.newRange },
  --     restore_selection = true,
  --   })
end

---Generates a random string
---@param v integer Lenght of the random string
---@return string The random string
local function randomString(v)
	local length = math.random(10,v)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(48, 122))
	end
	return table.concat(array)
end

---Return the temp directory for the given
---platform and detection if running on
---remote extension
---@return string
local get_tmp_dir = function ()
  if not vim.fn.has('win32') then
    return '/tmp'
  end

  -- If the avobe was true, it means we are using windows nvim binary
  -- Detect if file is currently working on the remote extension.
  local _, matches = vim.fn.expand('%:p'):gsub('vscode%-remote:', '')

  -- It matches when using the remote extension
  if matches > 0 then
    -- Defaults to current workspace open in vscode remote
    -- Same as attempting to save using `/tmp` as root is unaccessible from windows nvim
    -- And attempting to save using C:/Users/USER/AppData/Local/Temp will result
    -- in saving file under ~/Temp in the remote filesystem
    return 'tmp'
  end

  return vim.fn.substitute(os.getenv('TEMP') or '', '\\', '/', 'g')
end

---Saves backup of file
---@param file string Filename to backup
local backup_file = function (file)
  -- Save current changes
  -- local vscode = require('vscode')
  -- vscode.call('workbench.action.files.save')
  vim.cmd.write()
  local bac_file = vim.fn.fnamemodify(file, ':t')
  local tmp_dir = get_tmp_dir()
  local hash = randomString(10):gsub("[\\/:!?*%[%]%%\"\'><`^, ]", '_')
  -- /path/to/tmp/filename-with-ext.timestamp_10-char-hash.bac
  local back_name = tmp_dir .. '/' .. bac_file .. '.' .. os.time() .. '_' .. hash .. '.bac'
  vim.print('Backup at: '..back_name)
  vim.uv.fs_copyfile(file, back_name)
  -- vim.cmd('write! '.. back_name)
end

---Revert all changes in the file using the git cli
local revert_all_changes = function ()
  local file = get_file()
  pcall(backup_file, file) -- Attempt to backup file before reset
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

registerGit()

return {
  is_cursor_in_hunk = is_cursor_in_hunk,
  get_hunks = get_hunks,
  get_hunk_under_cursor = get_hunk_under_cursor_cli,
  get_file = get_file,
  stage_hunk_under_cursor = stage_hunk_under_cursor,
  stage_hunk_under_cursor_vscode = stage_hunk_under_cursor_vscode,
  unstage_hunk_under_cursor = unstage_hunk_under_cursor,
  unstage_hunk_under_cursor_vscode = unstage_hunk_under_cursor_vscode,
  revert_hunk_under_cursor = revert_hunk_under_cursor,
  revert_hunk_under_cursor_vscode = revert_hunk_under_cursor_vscode,
  revert_all_changes = revert_all_changes,
}

