
-- FIX: Treesitter failing to detect parser for textobjects
-- If the issue somehow still happens, try using `]m` or `[m` to force
-- loading the treesitter parser
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('Treesitter.Buf.Enter', { clear = true }),
  callback = vim.schedule_wrap(function()
    pcall(function() vim.treesitter.get_parser():parse() end)
  end)
})


-- FIX: Initial path setup when starting in WSL
-- with either windows nvim or linux nvim
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function (args)
    coroutine.resume(coroutine.create(vim.schedule_wrap(function ()
      local vscode = require('vscode')
      local workspace = vscode.eval('return  vscode.workspace.workspaceFolder || vscode.workspace.workspaceFolders[0]')
      -- Both WSL nvim and windows nvim use same scheme
      local is_remote = workspace and workspace.uri and workspace.uri.scheme == 'vscode-remote'
      if not is_remote then
        return
      end

      local expanded = require('lib.fs').expand_path(workspace.uri.path)
      pcall(vim.cmd.cd, expanded)
    end)))
  end,
})
