---@alias terminal.descriptor_callback_fn fun(jobId: integer, data: string[], name: string)

---@class terminal.open_terminal
---@field cwd? string Directory to start lf from
---@field fullscreen? boolean Open on fullscreen
---@field cmd string[] command to run in terminal
---@field env? table<string, string> environment variables to set
---@field ft? string filetype for buffer
---@field bt? string buftype for buffer
---@field name? string name for buffer
---@field on_exit? terminal.descriptor_callback_fn
---@field on_stdout? terminal.descriptor_callback_fn
---@field on_stderr? terminal.descriptor_callback_fn
---@field stderr_buffered? boolean
---@field stdout_buffered? boolean
---@field stdin? 'pipe'|'null'
---@field clear_env? boolean

local def_int_buf_name = 'interactive_terminal'

---Use lf in neovim to select and open files for editing
---@param opts? terminal.open_terminal
local function open_terminal_interactive(opts)
  opts = opts or {}

  if (not opts.cmd) or #opts.cmd == 0 then
    return
  end

  -- Store current buffer reference for navigating back
  local curr_buf = vim.api.nvim_get_current_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  ---@type nil|integer
  local temporaryTabId = nil
  ---@type boolean
  local fullscreen = opts.fullscreen ~= nil and opts.fullscreen or false
  -- Priorities
  -- repository > buffer dir > home directory
  local cwd = ''
  local dir = opts.cwd
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
  -- Check if cwd is assinged, if not try to guess a suitable directory
  cwd = cwd or require('lib.fs').git_path() or vim.fn.expand('%:p:h')
  if not vim.fn.isdirectory(cwd) then
    -- Try find root of git directory by .git file/dir
    cwd = require('utils.stdlib').find_root('.git') --[[@as string]]
    if cwd == nil then
      -- Fallback to home
      cwd = vim.fn.expand('~')
    end
  end
  pcall(vim.api.nvim_set_option_value, 'filetype', opts.ft or def_int_buf_name, { buf = buf })
  pcall(vim.api.nvim_set_option_value, 'buftype', opts.bt or def_int_buf_name, { buf = buf })

  -- Enable insert mode on open
  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = buf,
    callback = function()
      vim.cmd.startinsert()
    end,
  })

  -- For cleanup (if needed)
  -- vim.api.nvim_create_autocmd('TermClose', {
  --   once = true,
  --   buffer = buf,
  --   callback = function ()
  --     -- Term specific cleanup
  --     -- vim.fn.feedkeys('i')
  --   end
  -- })

  if fullscreen then
    -- Open new tab to ensure fullscreen
    vim.cmd.tabnew()
    temporaryTabId = vim.api.nvim_get_current_tabpage()
  end

  -- Apend buffer in current window
  vim.api.nvim_win_set_buf(0, buf)

  -- Run termopen on the context of the created buffer
  vim.api.nvim_buf_call(buf, function()
    -- Name the buffer
    pcall(vim.api.nvim_buf_set_name, buf, opts.name or ('terminal: %s'):format(opts.cmd[1]))
    vim.fn.jobstart(opts.cmd, {
      cwd = cwd,
      env = opts.env,
      clear_env = opts.clear_env,
      term = true,
      on_exit = function(jobId, data, name)
        -- local on_close = function()
        --   if fullscreen then
        --     -- Needed to remove "[Process exited 0]"
        --     vim.fn.feedkeys('i')
        --     return
        --   end
        --
        --   -- Check if buffer from where LF open is still available
        --   -- and go back to it. Fallback to :bnext otherwise.
        --   if vim.api.nvim_buf_is_loaded(curr_buf) then
        --     vim.cmd.buffer(curr_buf)
        --   else
        --     vim.cmd.bnext()
        --   end
        -- end

        -- Decide if it should close the tab
        if
          fullscreen
          and type(temporaryTabId) == 'number'
          and vim.api.nvim_tabpage_is_valid(temporaryTabId)
          and vim.api.nvim_get_current_tabpage() == temporaryTabId
          and #(vim.api.nvim_list_tabpages()) > 1
        then
          vim.cmd.tabclose()
        end

        if opts.on_exit then
          opts.on_exit(jobId, data, name)
        else
          if fullscreen then
            -- Needed to remove "[Process exited 0]"
            vim.api.nvim_input('<esc>')
            return
          end

          -- Check if buffer from where terminal was opened is still available
          -- and go back to it. Fallback to :bnext otherwise.
          if vim.api.nvim_buf_is_loaded(curr_buf) then
            vim.cmd.buffer(curr_buf)
          else
            vim.cmd.bnext()
          end
        end
      end,
      on_stderr = opts.on_stderr,
      on_stdout = opts.on_stdout,
      stderr_buffered = opts.stderr_buffered,
      stdout_buffered = opts.stdout_buffered,
    })
  end)
end

return {
  open_terminal_interactive = open_terminal_interactive,
}
