local vscode = require('vscode')

vim.api.nvim_create_user_command('BCloseAllBuffers', function ()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window' })

vim.api.nvim_create_user_command('BCloseCurrent', function ()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window' })

vim.api.nvim_create_user_command('BCloseOthers', function ()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window' })

