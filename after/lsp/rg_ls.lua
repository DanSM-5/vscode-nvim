local name = 'rg_ls'

return {
  name = name,
  on_attach = function(client, bufnr)
    local triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz', '')
    require('utils.lsp_maps').set_lsp_keys(client, bufnr)
    require('utils.complete').configure(client, bufnr, { triggerCharacters = triggerCharacters })
  end,
  cmd = function(...)
    return require('lib.lsp.rg_ls').register(...)
  end,
  root_markers = { '.git' },
  workspace_required = false,
  ---@type rg.settings
  settings = {
    rg = {
      debounce = 500,
    }
  },
}
