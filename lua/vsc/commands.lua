local vscode = require('vscode')

-- Close all buffers
vim.api.nvim_create_user_command('BCloseAllBuffers', function()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window', bar = true })
vim.api.nvim_create_user_command('Bda', function()
  vscode.action('workbench.action.closeEditorsInGroup')
end, { desc = '[vscode] Close all buffers in window', bar = true })

-- Close current buffer
-- TODO: Fix issue of buffer not closign
vim.api.nvim_create_user_command('BCloseCurrent', function()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window', bar = true })
vim.api.nvim_create_user_command('Bd', function()
  vscode.action('workbench.action.closeActiveEditor')
end, { desc = '[vscode] Close current buffer in window', bar = true })

-- Close all other buffers
vim.api.nvim_create_user_command('BCloseOthers', function()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window', bar = true })
vim.api.nvim_create_user_command('Bdo', function()
  vscode.action('workbench.action.closeOtherEditors')
end, { desc = '[vscode] Close all other buffers in window', bar = true })

-- Fzf-like
vim.api.nvim_create_user_command('RG', function(args)
  local query = table.concat(args.fargs or {}, ' ')
  vscode.action('workbench.action.findInFiles', {
    args = {
      query = query,
    },
  })
end, { desc = '[vscode] Search in workspace', nargs = '*', bar = true, bang = true })

vim.api.nvim_create_user_command('GitFZF', function(args)
  if args.bang then
    vscode.action('find-it-faster.findFiles')
  else
    local query = table.concat(args.fargs or {}, ' ')
    vscode.action('workbench.action.quickOpen', {
      args = { query },
    })
  end
end, { desc = '[vscode] search file in workspace', nargs = '*', bar = true, bang = true, complete = 'dir' })

vim.api.nvim_create_user_command('Files', function()
  vscode.action('find-it-faster.findFiles')
end, { desc = '[vscode] search file in workspace', nargs = '*', bar = true, bang = true })

vim.api.nvim_create_user_command('Buffers', function(args)
  local query = table.concat(args.fargs or {}, ' ')
  vscode.action('workbench.action.quickOpen', {
    args = { query },
  })
end, { desc = '[vscode] search file in workspace', nargs = '*', bar = true, bang = true, complete = 'dir' })

vim.api.nvim_create_user_command('Colors', function(args)
  vscode.action('workbench.action.selectTheme')
end, { desc = '[vscode] select theme', nargs = 0, bar = true, bang = true })

vim.api.nvim_create_user_command('BLines', function(args)
  vscode.action('workbench.action.gotoLine')
end, { desc = '[vscode] jump to line', nargs = 0, bar = true, bang = true })

-- Lsp

vim.api.nvim_create_user_command('CodeActions', function(args)
  vscode.action('editor.action.quickFix')
end, { desc = '[vscode] Code actions', bang = true })

vim.api.nvim_create_user_command('Definitions', function(args)
  vscode.action('editor.action.revealDefinition')
end, { desc = '[vscode] Definitions', bang = true })

vim.api.nvim_create_user_command('Declarations', function(args)
  -- vscode.action('editor.action.peekDeclaration')
  vscode.action('editor.action.goToDeclaration')
end, { desc = '[vscode] Declarations', bang = true })

vim.api.nvim_create_user_command('TypeDefinitions', function(args)
  vscode.action('editor.action.goToTypeDefinition')
end, { desc = '[vscode] Implementations', bang = true })

vim.api.nvim_create_user_command('Implementations', function(args)
  if args.bang then
    vscode.action('editor.action.peekImplementation')
  else
    vscode.action('editor.action.goToImplementation')
  end
end, { desc = '[vscode] Implementations', bang = true })

vim.api.nvim_create_user_command('References', function(args)
  vscode.action('editor.action.referenceSearch.trigger')
end, { desc = '[vscode] References', bang = true })

vim.api.nvim_create_user_command('DocumentSymbols', function(args)
  vscode.action('workbench.action.gotoSymbol')
end, { desc = '[vscode] Document symbols', bang = true })

vim.api.nvim_create_user_command('WorkspaceSymbols', function(args)
  vscode.action('workbench.action.showAllSymbols')
end, { desc = '[vscode] Workspace symbols', bang = true })

vim.api.nvim_create_user_command('IncomingCalls', function(args)
  vscode.action('editor.showIncomingCalls')
end, { desc = '[vscode] Incoming Calls', bang = true })

vim.api.nvim_create_user_command('OutgoingCalls', function(args)
  vscode.action('editor.showOutgoingCalls')
end, { desc = '[vscode] Incoming Calls', bang = true })

vim.api.nvim_create_user_command('FunctionReferences', function(args)
  vscode.action('editor.showCallHierarchy')
end, { desc = '[vscode] Show call hierarchy', bang = true })

vim.api.nvim_create_user_command('Diagnostics', function(args)
  vscode.action('workbench.actions.view.problems')
end, { desc = '[vscode] Show diagnostics (errors and warnings)', bang = true })

vim.api.nvim_create_user_command('Todos', function(args)
  local keywords = #args.fargs > 0 and args.fargs or require('lib.fzf').todo_keywords
  local query = string.format('\\b(%s):', table.concat(keywords, '|'))

  vscode.action('workbench.action.findInFiles', {
    args = {
      query = query,
      isRegex = true,
    },
  })
end, {
  desc = '[vscode] find todos',
  bang = true,
  nargs = '*',
  complete = function(current)
    return require('lib.fzf').todos_complete(current)
  end,
})
