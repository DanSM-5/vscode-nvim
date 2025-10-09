---Make function dot repeatable for the peek definition module
---@generic T
---@param fn T
---@return T
local function make_dot_repeatable(fn)
  return function()
    _G._peek_definition_last_function = fn
    vim.o.opfunc = "v:lua._peek_definition_last_function"
    vim.api.nvim_feedkeys("g@l", "n", false)
  end
end

-- peeking is not interruptive so it is okay to use in visual mode.
-- in fact, visual mode peeking is very helpful because you may not want
-- to jump to the definition.
local nx_mode_functions = {
  peek_definition_code = '[TSModule] Show the definition of the query provided',
}


---@class (exact) ts.mod.lsp_interop.Config: ts.mod.module.Config
---@field data { keymap_modes: string|string[]; keymaps_per_buf: table<string, string>; dot_repeatable: boolean; floating_preview_opts?: vim.lsp.util.open_floating_preview.Opts }

---@class ts.mod.lsp_interop: ts.mod.Module
---@field public config ts.mod.lsp_interop.Config
local Module = {}

---@type ts.mod.lsp_interop.Config
Module.config = {
  enable = false,
  disable = false,
  data = {}
}

---@private
---@type table<integer, string>
Module.methods = {}

---@private
---@type table<integer, string>
Module.expressions = {}

---called from state on setup
---@param config ts.mod.lsp_interop.Config
function Module.setup(config)
  Module.config = config
end

---@return string
function Module.name()
  return 'lsp_interop'
end


---@param ctx ts.mod.Context
---@return boolean
function Module.enabled(ctx)
  local util = require('treesitter-modules.lib.util')
  return util.enabled(Module.config, ctx)
end

---@param ctx ts.mod.Context
function Module.attach(ctx)
  local keymap_modes = Module.config.data.keymap_modes or { 'n' }
  if type(keymap_modes) == "string" then
    keymap_modes = { keymap_modes }
  elseif type(keymap_modes) ~= "table" then
    keymap_modes = { "n" }
  end

  local keymaps_per_buf = Module.config.data.keymaps_per_buf or {}
  local dot_repeatable = Module.config.data.dot_repeatable or false

  for function_call, function_description in pairs(nx_mode_functions) do
    for mapping, query_metadata in pairs(keymaps_per_buf or {}) do
      local mapping_description, query, query_group

      if type(query_metadata) == "table" then
        query = query_metadata.query
        query_group = query_metadata.query_group or "textobjects"
        mapping_description = query_metadata.desc
      else
        query = query_metadata
        query_group = "textobjects"
        mapping_description = function_description .. " " .. query_metadata
      end

      local fn = function()
        require('lib.treesitter.ts_lsp_interop').peek_definition_code(query, query_group)
      end
      if dot_repeatable then
        fn = make_dot_repeatable(fn)
      end

      pcall(
        vim.keymap.set,
        keymap_modes,
        mapping,
        fn,
        { buffer = ctx.buf, silent = true, noremap = true, desc = mapping_description }
      )
    end
  end
end

---@param ctx ts.mod.Context
function Module.detach(ctx)
  local buf = ctx.buf or vim.api.nvim_get_current_buf()
  local keymaps_per_buf = Module.config.data.keymaps_per_buf or {}
  local keymap_modes = Module.config.data.keymap_modes or { 'n' }
  if type(keymap_modes) == "string" then
    keymap_modes = { keymap_modes }
  elseif type(keymap_modes) ~= "table" then
    keymap_modes = { "n" }
  end

  for mapping, query_metadata in pairs(keymaps_per_buf or {}) do
     -- Even if it fails make it silent
    pcall(vim.keymap.del, keymap_modes, mapping, { buffer = buf })
  end
end


---Get available textobjects
---@param opts { lang?: string; buf: integer; query_group: string }
---@return string[]
local function available_textobjects(opts)
  -- local lsp_interop = require('lib.treesitter.ts_lsp_interop')
  -- local lang = opts.lang or lsp_interop.utils.get_buf_lang(opts.buf)

  local lang = opts.lang or vim.treesitter.language.get_lang(
    vim.api.nvim_get_option_value('filetype', { buf = opts.buf })
  )

  if lang == nil then
    return {}
  end
  local query_group = opts.query_group or "textobjects"
  local parsed_queries = vim.treesitter.query.get(lang, query_group)
  if not parsed_queries then
    return {}
  end
  local found_textobjects = parsed_queries.captures or {}
  for _, p in pairs(parsed_queries.info.patterns) do
    for _, q in ipairs(p) do
      local query, arg1 = unpack(q)
      if query == "make-range!" and not vim.tbl_contains(found_textobjects, arg1) then
        table.insert(found_textobjects, arg1)
      end
    end
  end
  return found_textobjects
  --patterns = {
  --[2] = { { "make-range!", "function.inner", 2, 3 } },
  --[4] = { { "make-range!", "function.inner", 2, 3 } },
  --[11] = { { "make-range!", "parameter.outer", 2, 12 } },
  --[12] = { { "make-range!", "parameter.outer", 12, 3 } },
  --[13] = { { "make-range!", "parameter.outer", 2, 12 } },
  --[14] = { { "make-range!", "parameter.outer", 12, 3 } }
  --}
end

-- Create command peek definition
vim.api.nvim_create_user_command('TSPeekDefinitionCode', function(args)
  local lsp_interop = require('lib.treesitter.ts_lsp_interop')
  lsp_interop.peek_definition_code(unpack(args.fargs))
end, {
  complete = function (current, cmd)
    if #vim.split(cmd, ' ') > 2 then
      return {}
    end

    local buf = vim.api.nvim_get_current_buf()
    local lang = vim.treesitter.language.get_lang(
      vim.api.nvim_get_option_value('filetype', { buf = buf })
    )
    local available_to = vim.tbl_map(function (to) return '@'..to end, available_textobjects({ lang = lang, buf = buf }))

    ---@type string[]
    local matched = vim.tbl_filter(function (to)
      local _, matches = string.gsub(to, '^'..current, '')
      return matches > 0
    end, available_to)

    return #matched > 0 and matched or available_to

  end,
  bang = true,
  desc = '[TS] Peak definition on float window',
  nargs = '+',
})


return Module
