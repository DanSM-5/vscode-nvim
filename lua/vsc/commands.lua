local vscode = require('vscode')

-- Close all buffers
vim.api.nvim_create_user_command('BCloseAllBuffers', function ()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window', bar = true })
vim.api.nvim_create_user_command('Bda', function ()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window', bar = true })

-- Close current buffer
-- TODO: Fix issue of buffer not closign
vim.api.nvim_create_user_command('BCloseCurrent', function ()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window', bar = true })
vim.api.nvim_create_user_command('Bd', function ()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window', bar = true })

-- Close all other buffers
vim.api.nvim_create_user_command('BCloseOthers', function ()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window', bar = true })
vim.api.nvim_create_user_command('Bdo', function ()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window', bar = true })
