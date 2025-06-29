
---@type vim.lsp.Config
return {
  settings = {
    -- sort sources by name. Sources that show up first will be given priority
    -- group sources together to show their completion suggestions at the same time like:
    -- `{ { 'path', 'lsp' }, { 'buffer' } }`
    -- for the above, 'buffer' will only show if 'path' and 'lsp' produce no results
    sources = {
      {
        { name = 'rg', keyword_length = 3 } -- entry
      }, -- group 1
    },
  },
}
