---Use lf in neovim to select and open files for editing
---@param dir? string Directory to start lf from
---@param fullscreen? boolean Open on fullscreen
local lf = function(dir, fullscreen)
  -- Store current buffer reference for navigating back
  local curr_buf = vim.api.nvim_get_current_buf()
  local temp = vim.fn.tempname()
  local buf = vim.api.nvim_create_buf(false, true)
  ---@type nil|integer
  local temporaryTabId = nil
  -- Priorities
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
  -- Check if cwd is assinged, if not try to guess a suitable directory
  cwd = cwd or vim.fn['utils#git_path']() or vim.fn.expand('%:p:h')
  if not vim.fn.isdirectory(cwd) then
    -- Try find root of git directory by .git file/dir
    cwd = require('utils.stdlib').find_root('.git') --[[@as string]]
    if cwd == nil then
      -- Fallback to home
      cwd = vim.fn.expand('~')
    end
  end
  pcall(vim.api.nvim_set_option_value, 'filetype', 'lf_buffer', { buf = buf })

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
    vim.api.nvim_buf_set_name(buf, 'LF Select')
    vim.fn.termopen({ 'lf', '-selection-path=' .. temp }, {
      cwd = cwd,
      on_exit = function(jobId, code, evt)
        -- NOTE: when closing without selection we need to
        -- move to a different buffer to avoid afecting
        -- the window layout.
        local on_no_selection = function()
          if fullscreen then
            -- Needed to remove "[Process exited 0]"
            vim.fn.feedkeys('i')
            return
          end

          -- Check if buffer from where LF open is still available
          -- and go back to it. Fallback to :bnext otherwise.
          if vim.api.nvim_buf_is_loaded(curr_buf) then
            vim.cmd.buffer(curr_buf)
          else
            vim.cmd.bnext()
          end
        end

        local ok_fileredable = pcall(vim.fn.filereadable, temp)
        if not ok_fileredable then
          on_no_selection()
          return
        end

        local ok_names, names = pcall(vim.fn.readfile, temp)

        if not ok_names then
          on_no_selection()
          return
        end

        if #names == 0 then
          on_no_selection()
          return
        end

        if
          fullscreen
          and type(temporaryTabId) == 'number'
          and vim.api.nvim_tabpage_is_valid(temporaryTabId)
          and vim.api.nvim_get_current_tabpage() == temporaryTabId
          and #(vim.api.nvim_list_tabpages()) > 1
        then
          vim.cmd.tabclose()
        end

        for i = 1, #names do
          if i == 1 then
            vim.fn.execute('edit ' .. vim.fn.fnameescape(names[i]))
          else
            vim.fn.execute('argadd ' .. vim.fn.fnameescape(names[i]))
          end
        end
      end,
    })
  end)
end

return {
  lf = lf,
}
