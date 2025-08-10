---@class cmp_compat.sources
---@field add_source fun(s: table) Add source function
---@field sort_sources fun(config: table) Sources configuration
---@field sources table sources for cmp
local module = {}

-- track all the sources
module.sources = {}

module.add_source = function(s)
  table.insert(module.sources, s)

  -- Configuration comes from in-process lsp
  module.sort_sources(
    vim.lsp.config.cmp2lsp.settings.sources --[[@as table]]
  )
end

---Sort sources by configuration order
---@param name string
---@return table|nil
local source_by_name = function(name)
  for _, source in ipairs(module.sources) do
    if source.name == name then
      return source
    end
  end
end

---Sort sources into configuration order
module.sort_sources = function(config)
  local sorted = {}

  for _, group in ipairs(config) do
    for _, item in ipairs(group) do
      ---@type string
      local name

      if type(item) == 'string' then
        name = item
      else
        name = item.name
      end

      local source = source_by_name(name)
      if not source then
        vim.notify(('[cmp2lsp] invalid source name: `%s`'):format(name), vim.log.levels.WARN, {})
        return
      end

      if type(item) == 'table' then
        source.cmp2lsp = {}
        source.cmp2lsp.keyword_length = item.keyword_length or 0
        source.cmp2lsp.kind = item.kind or 1
      end

      table.insert(sorted, source)
    end

    -- TODO: investigate below group separator
    -- Original message:
    -- "yeah this is horribly hacky. it's a small plugin okay."
    table.insert(sorted, 'group separator')
  end

  module.sources = sorted
end

return module
