---@type vim.lsp.Config
return {
  cmd = function(dispatchers)
    local cmd = {
      'stylua',
      '--lsp',
    }

    local path = vim.api.nvim_buf_get_name(0)
    local config = vim.fs.find({ '.stylua.toml', 'stylua.toml', '.editorconfig' }, {
      path = path,
      upward = true,
    })[1]

    if config then
      table.insert(cmd, '--config-path')
      table.insert(cmd, config)
    end

    return vim.lsp.rpc.start(cmd, dispatchers)
  end,
  -- cmd = { 'stylua', '--lsp' },
  filetypes = { 'lua' },
  root_markers = { '.stylua.toml', 'stylua.toml', '.editorconfig' },
}
