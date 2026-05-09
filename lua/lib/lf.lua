---Use lf in neovim to select and open files for editing
---@param dir? string Directory to start lf from
---@param fullscreen? boolean Open on fullscreen
local lf = function(dir, fullscreen)
  local terminal = require('lib.terminal')

  -- Remember the window we came from so we can return to it (and edit
  -- the selected files there) when lf exits. This is the window that
  -- existed BEFORE win_term creates / picks one to host the terminal.
  local origin_win = vim.api.nvim_get_current_win()
  local temp = vim.fn.tempname()

  -- Priorities:
  -- repository > buffer dir > home directory
  local cwd = ''
  if dir == '.' or dir == '%' then
    -- dot (.) and buffer (%) expand to current dir
    cwd = vim.fn.expand('%:p:h')
  elseif dir == '~' then
    -- tilda (~) expand to home
    cwd = vim.fn.expand('~')
  elseif dir ~= nil then
    -- get absolute path always in case it passed relative
    cwd = vim.fn.fnamemodify(dir, ':p:h')
  end
  -- Check if cwd is assigned, if not try to guess a suitable directory
  cwd = cwd or require('lib.fs').git_path() or vim.fn.expand('%:p:h')
  if not vim.fn.isdirectory(cwd) then
    -- Try find root of git directory by .git file/dir
    cwd = require('lib.std').find_root('.git') --[[@as string]]
    if cwd == nil then
      -- Fallback to home
      cwd = vim.fn.expand('~')
    end
  end

  -- Delegate window/buffer management to win_term so that:
  --   - fullscreen opens in a new tabpage (closed on exit)
  --   - a single-window tabpage gets a vertical split (closed on exit)
  --   - otherwise the focused window is reused and the previous buffer
  --     restored on exit (preserving the layout)
  terminal.win_term({
    cmd = { 'lf', '-selection-path=' .. temp },
    fullscreen = fullscreen,
    name = 'LF Select',
    ft = 'lf_buffer',
    term = {
      cwd = cwd,
      on_exit = function()
        -- Defer to the main loop: by the time this runs, win_term's
        -- TermClose handler has already disposed the terminal window
        -- (either closing it or restoring the previous buffer).
        vim.schedule(function()
          local ok_readable, readable = pcall(vim.fn.filereadable, temp)
          if not ok_readable or readable == 0 then
            return
          end

          local ok_names, names = pcall(vim.fn.readfile, temp)
          pcall(os.remove, temp)

          if not ok_names or #names == 0 then
            -- No selection: nothing else to do, win_term already
            -- handled the layout restoration.
            return
          end

          -- Open the selected files in the window we came from. It
          -- may have been preserved (fullscreen / vsplit cases) or
          -- replaced with the previous buffer (reused-window case);
          -- either way, the selected file overrides it.
          if vim.api.nvim_win_is_valid(origin_win) then
            pcall(vim.api.nvim_set_current_win, origin_win)
          end

          for i = 1, #names do
            if i == 1 then
              vim.cmd.edit(vim.fn.fnameescape(names[i]))
            else
              vim.cmd.argadd(vim.fn.fnameescape(names[i]))
            end
          end
        end)
      end,
    },
  })
end

return {
  lf = lf,
}
