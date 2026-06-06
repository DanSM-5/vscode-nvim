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
    globalThis._vscode_git = {
      constants: {
        MAX_BUFFER: 64 * 1024 * 1024, // 64 MiB, for large staged diffs
        TAG: '[gitvscode]',
      },

      /**
       * Utility function to detect if VSCode is running in remote mode in WSL
       * @returns {boolean} Whether or not it is running in wsl
       */
      isWsl: () => {
        const os = require('os');
        return (
          os.platform() === 'linux' &&
          os.release().toLowerCase().includes('microsoft')
        );
      },

      /**
       * Get remote data about the current VSCode environment,
       * including whether it's WSL, the WSL distro name, the URI scheme, and the workspace path.
       * @returns {{ is_wsl: boolean; distro: string; scheme: string; path: string; }}
       */
      getRemoteData: () => {
        const workspace = vscode?.workspace ?? {};
        const folder =
          workspace.workspaceFolder ?? workspace.workspaceFolders?.[0] ?? {};
        const uri = folder.uri ?? {};
        const authority = uri.authority ?? '';
        const is_wsl = authority.includes('wsl+');
        return {
          is_wsl,
          distro: authority.replace('wsl+', '').trim() ?? '',
          scheme: uri.scheme ?? 'unknown',
          path: (is_wsl ? uri.path : uri.path?.replace?.(/^\//, '')) ?? '',
        };
      },

      /**
       * Utility to get the appropriate git command and arguments, adjusted for WSL if necessary.
       * @returns {{ command: string; args: string[]; }} Arguments to use for git commands, adjusted for WSL if necessary
       */
      getGitCommand: () => {
        const getRemoteData = globalThis._vscode_git.getRemoteData;
        const remoteData = getRemoteData();

        if (!remoteData.is_wsl) {
          return {
            command: 'git',
            args: [
              '-C',
              remoteData.path,
            ],
          };
        }

        // In WSL, use the native git from the wsl distro to ensure correct path
        // handling and permissions. This also avoids issues with line endings and file modes.

        return {
          command: 'wsl',
          args: [
            '--distro',
            remoteData.distro,
            '--exec',
            'git',
            '-C',
            remoteData.path,
          ],
        };
      },

      /**
       *
       * @param {number} n Line number
       * @param {[number, number][]} intervals ranges of lines to select, where each range is [lo, hi] (hi=null means open-ended)
       * @returns {boolean} True if the line is selected, false otherwise
       */
      selected: (n, intervals) => {
        for (let i = 0; i < intervals.length; i++) {
          const lo = intervals[i][0],
            hi = intervals[i][1];
          if (lo <= n && (hi === null || n <= hi)) return true;
        }
        return false;
      },
      /**
       * Builds a git patch that unstages the specified changes from the given diff.
       * @param {string} diff Patch of staged changes
       * @param {[number, number][]} intervals ranges of lines to select, where each range is [lo, hi] (hi=null means open-ended)
       * @returns {string} Updated git patch
       */
      buildPatch: (diff, intervals) => {
        const selected = globalThis._vscode_git.selected;
        const lines = diff.split('\n');
        if (lines.length && lines[lines.length - 1] === '') lines.pop(); // mirror Python splitlines()
        const out = [];
        let newLn = 0,
          inHunk = false;
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          if (
            line.indexOf('diff ') === 0 ||
            line.indexOf('index ') === 0 ||
            line.indexOf('--- ') === 0 ||
            line.indexOf('+++ ') === 0
          ) {
            out.push(line);
            continue; // file headers
          }
          if (line.indexOf('@@') === 0) {
            out.push(line); // --recount fixes the numbers
            // @@ -old_start,old_len +new_start,new_len @@  -> seed new-file counter
            const seg = line.split('@@')[1].trim();
            const parts = seg.split(' ');
            newLn = parseInt(parts[1].slice(1).split(',')[0], 10); // strip leading '+'
            inHunk = true;
            continue;
          }
          if (!inHunk) {
            out.push(line);
            continue;
          } // extended headers (mode/rename/etc.)
          const tag = line.charAt(0);
          const text = line.slice(1);
          if (tag === ' ') {
            // context: present on both sides
            out.push(line);
            newLn++;
          } else if (tag === '+') {
            // addition: index side only
            out.push(selected(newLn, intervals) ? line : ' ' + text); // keep -> unstage; else context
            newLn++;
          } else if (tag === '-') {
            // deletion: matched by new-file position
            if (selected(newLn, intervals)) out.push(line); // keep -> reverse-apply re-includes it
            // else: drop it (stays staged; not present in index, can't be context)
            // newLn is NOT advanced: a deletion occupies no new-file line.
          } else {
            out.push(line); // "\ No newline at end of file", etc.
          }
        }
        return out.join('\n') + '\n';
      },

      /**
       * Run a git command synchronously, returning stdout as a string. Throws on error.
       * @param {string[]} gitArgs Arguments for git
       * @param {string} input Stdin for git command
       * @returns {string} result of command
       */
      gitExecSync: (gitArgs, input) => {
        const { execFileSync } = require('child_process');
        const getGitCommand = globalThis._vscode_git.getGitCommand;
        const gitCommand = getGitCommand();
        const opts = {
          encoding: 'utf8',
          maxBuffer: globalThis._vscode_git.constants.MAX_BUFFER,
          ...(input != null ? { input } : {}),
        };
        const command = gitCommand.command;
        const finalArgs = [...gitCommand.args, ...gitArgs];
        const TAG = globalThis._vscode_git.constants.TAG;
        logger.info(`${TAG}[gitExecSync] Execute command:`, command, finalArgs);
        return execFileSync(
          command,
          finalArgs,
          opts,
        ).toString();
      },
      /**
       * Run a git command asynchronously, returning a Promise that resolves to stdout as a string. Rejects on error.
       * @param {string[]} gitArgs Arguments for git
       * @param {string} input Stdin for git command
       * @returns {Promise<string>} result of command
       */
      gitExec: (gitArgs, input) => {
        return new Promise(function (resolve, reject) {
          const { execFile } = require('child_process');
          const getGitCommand = globalThis._vscode_git.getGitCommand;
          const gitCommand = getGitCommand();
          const command = gitCommand.command;
          const finalArgs = [...gitCommand.args, ...gitArgs];
          const TAG = globalThis._vscode_git.constants.TAG;
          logger.info(`${TAG}[gitExec] Execute command:`, command, finalArgs);

          var child = execFile(
            command,
            finalArgs,
            {
              encoding: 'utf8',
              maxBuffer: globalThis._vscode_git.constants.MAX_BUFFER,
            },
            function (err, stdout, stderr) {
              if (err) {
                err.message += stderr ? '\n' + stderr : '';
                reject(err);
              } else resolve(stdout);
            },
          );
          if (input != null) child.stdin.end(input); // pipe patch to git apply's stdin
        });
      },

      /**
       * Unstages a hunk of changes from a file based on the provided options.
       * It retrieves the staged changes for the specified file, builds a patch
       * that unstages the specified line range, and applies the patch to
       * unstage the changes. The function can run either synchronously or
       * asynchronously based on the 'sync' option.
       * @param {{ file: string, sync: boolean, start?: number, end?: number }} opts Options for unstaging a hunk of changes from a file. 'file' is the path to the file, 'sync' determines whether to run synchronously or asynchronously, and 'start' and 'end' specify the line range to unstage (1-based, inclusive; if 'end' is omitted, it unstages from 'start' to the end of the file).
       * @param {string} opts.file The path to the file to unstage changes from.
       * @param {boolean} [opts.sync=false] Whether to run the git commands synchronously or asynchronously.
       * @param {number} [opts.start=1] The starting line number of the range to unstage (1-based).
       * @param {number} [opts.end] The ending line number of the range to unstage (inclusive). If omitted, it unstages from 'start' to the end of the file.
       * @returns {string} The result of the git command. Empty string if async.
       */
      unstageHunk: opts => {
        // From 'lib.fs' to ensure correct path handling on WSL and Windows.
        const file = opts.file;
        const sync = opts.sync ?? false;
        const start = opts.start || 1;
        const end = opts.end;
        const intervals = [
          [start, end],
        ];
        const buildPatch = globalThis._vscode_git.buildPatch;
        const gitArgsDiff = ['diff', '--cached', '--', file];
        const gitArgsApply = ['apply', '--cached', '-R', '--recount'];

        const TAG = globalThis._vscode_git.constants.TAG;
        logger.info(`${TAG}[unstageHunk] Info:`, intervals);

        if (sync) {
          const gitExecSync = globalThis._vscode_git.gitExecSync;
          const diff = gitExecSync(gitArgsDiff);
          const patch = buildPatch(diff, intervals);
          const result = gitExecSync(gitArgsApply, patch);

          return result;
        }

        const gitExec = globalThis._vscode_git.gitExec;
        gitExec(gitArgsDiff).then(diff => {
          const patch = buildPatch(diff, intervals);
          return gitExec(gitArgsApply, patch);
        });
        return '';
      },

      /**
       * Utility function to get line under the cursor
       * @returns {number} Line number where the cursor is located
       */
      get_line: () => {
        const line = vscode.window.activeTextEditor?.selection?.active?.line ||
          vscode.window.activeTextEditor?.selection?.start?.line;

        // Lines in vscode are 0-based index, so increase by 1
        if (line != null) { return line + 1; }
      },

      /**
       * Utility to get the hunk under the specified line or the current line if omitted.
       * @param {object} [opts] Options for function
       * @param {number} [opts.line] Line number. Default current line.
       * @param {''|'HEAD'} [opts.ref] Ref to use to match against query
       * @returns {object} Hunk from vscode
       */
      get_hunk_in_line: (opts = {}) => {
        const get_line = globalThis._vscode_git.get_line;
        const line = opts.line ?? get_line();

        // Ref for comparing against query
        // Empty string for unstaged hunks
        // or 'HEAD' for all hunks.
        const ref = opts.ref == null ? '' : opts.ref;
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

        return hunk;
      },

      /**
       * @param {object} opts options for staging the hunk under the cursor
       * @param {string} opts.file The path to the file to unstage changes from.
       * @param {boolean} [opts.sync=false] Whether to run the git commands synchronously or asynchronously.
       * @returns {string} The result of the git command. Empty string if async.
       */
      unstage_hunk_under_cursor: (opts) => {
        const TAG = globalThis._vscode_git.constants.TAG;
        const get_hunk_in_line = globalThis._vscode_git.get_hunk_in_line;
        const unstageHunk = globalThis._vscode_git.unstageHunk;
        opts.ref = opts.ref ?? 'HEAD'; // ensure ref
        const hunk = get_hunk_in_line(opts);
        if (!hunk) {
          logger.info(`${TAG}[unstage_hunk_under_cursor]. Hunk not found`);
          return '';
        }

        const unstageOpts = {
          ...opts,
          start: hunk.modified.startLineNumber,
          end: hunk.modified.endLineNumberExclusive,
        };

        return unstageHunk(unstageOpts)
      },

      /**
       * Unstages the current selected lines
       * @param {{ file: string, sync: boolean }} opts Options for unstaging a hunk of changes from a file. 'file' is the path to the file, 'sync' determines whether to run synchronously or asynchronously, and 'start' and 'end' specify the line range to unstage (1-based, inclusive; if 'end' is omitted, it unstages from 'start' to the end of the file).
       * @param {string} opts.file The path to the file to unstage changes from.
       * @param {boolean} [opts.sync=false] Whether to run the git commands synchronously or asynchronously.
       * @returns {string} The result of the git command. Empty string if async.
       */
      unstage_selection: (opts) => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
          logger.info(`${TAG}[unstage_selection] No active editor found`);
          return false;
        }

        const selection = editor.selection;
        const unstageOpts = {
          ...opts,
          // Base-0 index but we require real line number
          start: selection.start.line + 1,
          end: selection.end.line + 1,
        };

        const unstageHunk = globalThis._vscode_git.unstageHunk;
        return unstageHunk(unstageOpts)
      },

      /**
       * @param {object} opts options for apply_command function
       * @param {'git.stageSelectedRanges'|'git.unstageSelectedRanges'|'git.revertSelectedRanges'} opts.command Command to execute
       * @param {number} opts.line Line number to apply
       * @param {''|'HEAD'} opts.ref String to compare against query. Empty string for unstaged hunks or 'HEAD' for all hunks
       * @returns {boolean} Whether the command run successfully or not
       */
      apply_command: (opts) => {
        try {
          const { command } = opts;
          const TAG = globalThis._vscode_git.constants.TAG;

          // Need command
          if (!command) {
            logger.info(`${TAG}[apply_command] No command provided`);
            return false;
          }

          const line = opts?.line == null ? globalThis._vscode_git.get_line() : opts.line;
          const ref = opts?.ref == null ? '' : opts.ref;

          if (line == null) {
            logger.info(`${TAG}[apply_command][${command}] Line line found to apply command`);
            return false;
          }

          const editor = vscode.window.activeTextEditor;

          if (!editor) {
            logger.info(`${TAG}[apply_command][${command}] No active editor found`);
            return false;
          }

          const get_hunk_in_line = globalThis._vscode_git.get_hunk_in_line;
          const hunk = get_hunk_in_line({ line, ref });

          if (!hunk) {
            logger.info(`${TAG}[apply_command][${command}]. Hunk not found`);
            return false;
          }

          logger.info(`${TAG}[apply_command] Found hunk:`, hunk);

          // logger.info(`${TAG}[apply_command] selection: `, selection);
          // logger.info(`${TAG}[apply_command] opts`, opts);

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

---Get the current hunk under the cursor
---@param staged? boolean Whether or not get the staged hunks
---@return Hunk? The hunk under the cursor or nil if non is found
local get_hunk_under_cursor_cli = function (staged)
  local file = require('lib.fs').get_file()
  if not file then
    return
  end

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



-- NOTE: First try extracting hunk from vscode, then fallback to git cli
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

-- Test in vscode
-- =require('vscode').eval('return require("child_process").execFileSync("git", ["diff", "--cached", "--", "C:/Users/daniel/projects/tabs-to-links/action/script.js"]).toString()')
local unstage_selection_vscode = function()
  local file = require('lib.fs').get_file(0)

  ---@type boolean
  local success = require('vscode').eval([[
    globalThis?._vscode_git?.unstage_selection?.(args);
  ]], {
      args = {
        file = file,
        sync = true,
      }
    })

  return success
end
local unstage_hunk_under_cursor_vscode = function ()
  local file = require('lib.fs').get_file(0)

  ---@type boolean
  local success = require('vscode').eval([[
    globalThis?._vscode_git?.unstage_hunk_under_cursor?.(args);
  ]], {
      args = {
        file = file,
        sync = true,
      }
    })

  return success

  -- apply_command_vscode({
  --   command = 'git.unstageSelectedRanges',
  --   ref = 'HEAD',
  -- })

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
  if not (vim.fn.has('win32') == 1) then
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
  if vim.g.vscode == 1 then
    -- NOTE: on vscode we use the native command with a sync call
    -- to allow the file to be fully saved before backing it up
    local vscode = require('vscode')
    vscode.call('workbench.action.files.save')
  else
    vim.cmd.write()
  end

  local bac_file = vim.fn.fnamemodify(file, ':t')
  local tmp_dir = get_tmp_dir()
  vim.fn.mkdir(tmp_dir, 'p') -- ensure exists
  local hash = randomString(10):gsub("[\\/:!?*%[%]%%\"\'><`^, ]", '_')
  -- /path/to/tmp/filename-with-ext.timestamp_10-char-hash.bac
  local back_name = tmp_dir .. '/' .. bac_file .. '.' .. os.time() .. '_' .. hash .. '.bac'
  vim.print('Backup at: '..back_name)
  vim.uv.fs_copyfile(file, back_name)
  -- vim.cmd('write! '.. back_name)
end

---Revert all changes in the file using the git cli
local revert_all_changes = function ()
  local file = require('lib.fs').get_file()
  -- return if no file was found
  if not file then
    return
  end
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

if vim.g.vscode == 1 then
  registerGit()
end

return {
  is_cursor_in_hunk = is_cursor_in_hunk,
  get_hunks = get_hunks,
  get_hunk_under_cursor = get_hunk_under_cursor_cli,
  stage_hunk_under_cursor = stage_hunk_under_cursor,
  stage_hunk_under_cursor_vscode = stage_hunk_under_cursor_vscode,
  unstage_hunk_under_cursor = unstage_hunk_under_cursor,
  unstage_hunk_under_cursor_vscode = unstage_hunk_under_cursor_vscode,
  unstage_selection_vscode = unstage_selection_vscode,
  revert_hunk_under_cursor = revert_hunk_under_cursor,
  revert_hunk_under_cursor_vscode = revert_hunk_under_cursor_vscode,
  revert_all_changes = revert_all_changes,
}

