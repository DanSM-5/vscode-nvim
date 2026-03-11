
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
      ---@type { scheme: string; path: string; authority: string; }
      local workspace = vscode.eval([[ 
        const wf = vscode?.workspace?.workspaceFolder ?? vscode?.workspace?.workspaceFolders?.[0] ?? {};
        const uri = wf.uri ?? {};

        return {
          scheme: uri.scheme ?? 'unknown',
          path: uri.path ?? '',
          authority: uri.authority ?? 'unknown',
        };
      ]])

      -- Both WSL nvim and windows nvim use same scheme
      local is_remote = workspace.scheme == 'vscode-remote'
      if not is_remote or vim.fn.isdirectory(workspace.path) == 0 then
        return
      end



      local expanded = require('lib.fs').expand_path(workspace.path)
      pcall(vim.cmd.cd, expanded)
    end)))
  end,
})
