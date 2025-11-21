local try_toggle_netrw = function ()
  -- NOTE: set nohidden to avoid orphan buffers
  vim.opt.hidden = false

  local cur_file = vim.fn.expand('%:t')
  local file_dir = vim.fn.expand('%:p:h')

  -- Check if Netrw is open
  local netrw_open = false
  for _, buffer in ipairs(vim.fn.getbufinfo()) do
    local _, matches = buffer.name:gsub('NetrwTreeListing', '')
    if matches > 0 then
      netrw_open = true
      break
    end
  end

  if cur_file ~= 'NetrwTreeListing' and (not netrw_open) then
    vim.g.custom_netrw_from_win = vim.api.nvim_get_current_win()
    vim.cmd('cd ' .. file_dir)
    local gitpath = require('lib.fs').git_path()
    -- WARN: Need to call Lex with the path or netrw will open on the
    -- previous window.
    -- Issue: https://groups.google.com/g/vim_dev/c/np1yarYC4Uo
    vim.cmd('silent Lex! ' .. file_dir)
    vim.cmd('cd ' .. gitpath)
    -- NOTE: Need to check for an optional trailing '*'
    vim.fn.search(' ' .. cur_file .. '\\*\\?$')
    -- vim.notify('Opening ' .. cur_file, vim.log.levels.INFO)

    -- vim.api.nvim_create_autocmd('BufFilePost', {
    --   once = true,
    --   callback = function ()
    --     vim.schedule(function ()
    --       vim.fn.feedkeys('I', 'n')
    --       vim.fn.feedkeys('I', 'n')
    --     end)
    --   end
    -- })

    -- BUG: Netrw will halt when using `-` to go up a directory
    -- It works fine after toggling the header once...
    -- This block whole purpose is to toggle the header and hope for the best
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_call(bufnr, function ()
      vim.cmd.normal('II')
    end)

  else
    vim.cmd.Lex({ bang = true })
    vim.g.custom_netrw_from_win = nil
  end
end

local toggle_netrw = function ()
  local cur_dir = vim.fn.getcwd()

  local toggled = pcall(try_toggle_netrw)
  if not toggled then
    vim.cmd('cd ' .. cur_dir)
  end

  vim.opt.hidden = true
end

local set_keymaps = function ()
  vim.keymap.set('n', '<leader>ve', toggle_netrw, {})
end

local set_autocmds = function ()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'netrw',
    callback = function () vim.opt_local.bufhidden = 'wipe' end,
    desc = '[NetRW] Cleanup buffer',
    group = vim.api.nvim_create_augroup('netrw_cleanup', { clear = true })
  })
end

local setup = function ()
  vim.g.netrw_banner = 0
  vim.g.netrw_browse_split = 4
  vim.g.netrw_altv = 1
  vim.g.netrw_winsize = 25
  vim.g.netrw_liststyle = 3
  vim.g.netrw_fastbrowse = 0
  vim.g.netrw_liststyle = 3

  set_keymaps()
  set_autocmds()
end

return {
  setup = setup,
  set_keymaps = set_keymaps,
  set_autocmds = set_autocmds,
  toggle_netrw = toggle_netrw,
}
