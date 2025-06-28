---@brief
---
--- https://github.com/antonk52/basics-language-server/
---
--- Buffer, path, and snippet completion
---
--- ```bash
--- npm install -g basics-language-server
--- ```

---@type vim.lsp.Config
return {
  cmd = { 'basics-language-server' },
  workspace_required = false,
  settings = {
    buffer = {
      enable = true,
      minCompletionLength = 3,
    },
    path = {
      enable = true,
    },
    snippet = {
      enable = true,
      sources = {
        vim.fn.substitute(vim.fn.stdpath('data'), '\\', '/', 'g') .. '/lazy/friendly-snippets/package.json'
      },
      matchStrategy = 'fuzzy',
    },
  },
  on_attach = function (client, bufnr)
    require('utils.lsp_maps').set_lsp_keys(client, bufnr)
    require('utils.complete').configure(client, bufnr)
  end,
}
