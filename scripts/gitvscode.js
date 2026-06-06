// Helper for git functions
// This is meant to be copy-pasted in the body of `registerGit`
// in `lua/utils/gitvscode.lua`

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

