local root_markers = {
  'emmyrc.json',
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  '.git',
}

---@type vim.lsp.Config
return {
  on_attach = function(client, bufnr)
    require('utils.lsp_maps').set_lsp_keys(client, bufnr)
    require('utils.complete').configure(client, bufnr, {
      triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz-@.', '')
    })

    -- For disabling autocomplete if not in blink
    -- local ok, blink = pcall(require, 'blink.cmp')
    -- if not ok then
    -- end
  end,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = root_markers,
  single_file_support = true,
  log_level = vim.lsp.protocol.MessageType.Warning,
  settings = {
    Lua = {
      codelens = { enable = true },
      signatureHelp = { enable = true },
      hint = {
        enable = true,
        paramName = 'All',
        paramType = true,
      },
      completion = {
        enable = true,
        autoRequire = true,
        callSnippet = 'Both',
        displayContext = 5,
        keywordSnippet = 'Both',
      },
      runtime = {
        version = 'LuaJIT',
        workspace = {
          checkThirdparty = false,
          library = {
            vim.env.VIMRUNTIME,
          },
        }
      },
      telemetry = { enable = false },
      workspace = { library = vim.api.nvim_get_runtime_file('', true), checkThirdparty = false },
      format = {
        enable = true,
        defaultConfig = {
          insert_final_newline = true,
          quote_style = 'single',
        },
      },
    },
  },
}
