-- local qfpeek = require('lib.qfpeek')
-- local ns_qfpeek = qfpeek.ns
local ns_qfpeek = 'QfPeek'

local qfpeek_map = vim.g.qfpeek_map or 'K'
local qfpeek_map_ignore = vim.g.qfpeek_map_ignore ~= 0

-- vim.api.nvim_buf_create_user_command(buf, qfpeek.ns, qfpeek.on_cmd, {
--   nargs = '*',
--   desc = 'Preview quickfix/location list entry under cursor',
-- })

-- append_undo_ftplugin(('delcommand -buffer %s'):format(qfpeek.ns))

if qfpeek_map_ignore and qfpeek_map ~= '' then
  ---Utility function to append to current b:undo_ftplugin
  ---@param cmd string
  local function append_undo_ftplugin(cmd)
    vim.b.undo_ftplugin = table.concat({
      vim.b.undo_ftplugin or '',
      cmd,
    }, ' | ')
  end

  local buf = vim.api.nvim_get_current_buf()
  vim.keymap.set('n', qfpeek_map, function ()
    local cmd_info = require('lib.qfpeek').on_cmd()
    if cmd_info then
      vim.keymap.set('n', 'q', cmd_info.close, { desc = '[QfPeek] close floating', buf = buf })
      vim.keymap.set('n', '<esc>', cmd_info.close, { desc = '[QfPeek] close floating', buf = buf })


      vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(cmd_info.win),
        -- group = augroup,
        once = true,
        callback = function()
          pcall(vim.keymap.del, 'n', 'q', { buf = buf })
          pcall(vim.keymap.del, 'n', '<esc>', { buf = buf })
        end,
      })
    end
  end, {
    buffer = buf,
    desc = '[QfPeek] Preview quickfix/location list entry under cursor',
  })

  --- uset keymap
  append_undo_ftplugin(('unmap <buffer> %s'):format(qfpeek_map))
end
