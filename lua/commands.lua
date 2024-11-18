local vscode = require('vscode')

-- Close all buffers
vim.api.nvim_create_user_command('BCloseAllBuffers', function ()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window', bar = true })

-- Close current buffer
-- TODO: Fix issue of buffer not closign
vim.api.nvim_create_user_command('BCloseCurrent', function ()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window', bar = true })

-- Close all other buffers
vim.api.nvim_create_user_command('BCloseOthers', function ()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window', bar = true })

-- Clean search highlight (ctrl-l)
vim.api.nvim_create_user_command('CleanSearch', function ()
  vim.cmd(':nohlsearch')
end, { desc = 'Clean search highlight', bar = true })

-- Clean all carriage return symbols
vim.api.nvim_create_user_command('CleanCR', function ()
  vim.cmd([[
    try
      silent exec '%s/\r$//g'
    catch
    endtry
  ]])
end, { desc = 'Clean carriage return characters', bar = true })

-- Clean all trailing spaces
vim.api.nvim_create_user_command('CleanTrailingSpaces', function ()
  vim.cmd([[silent exec '%s/\s\+$//e']])
end, { desc = 'Clean empty characters at the end of the line', bar = true })


-- Repeatable move commands
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMove', function ()
  require('utils.repeatable_move').repeat_last_move()
end, { desc = '[Repeatable] Repeat last move', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveOpposite', function ()
  require('utils.repeatable_move').repeat_last_move_opposite()
end, { desc = '[Repeatable] Repeat last move opposite', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveNext', function ()
  require('utils.repeatable_move').repeat_last_move_next()
end, { desc = '[Repeatable] Repeat last move in forward direction', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMovePrevious', function ()
  require('utils.repeatable_move').repeat_last_move_previous()
end, { desc = '[Repeatable] Repeat last move in backward direction', bar = true, bang = true })

