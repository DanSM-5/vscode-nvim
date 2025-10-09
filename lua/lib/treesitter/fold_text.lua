---@class (exact) ts.mod.fold_text.Config: ts.mod.module.Config

---@class ts.mod.fold_text: ts.mod.Module
---@field private config ts.mod.fold_text.Config
local Module = {}

---@type ts.mod.fold_text.Config
Module.config = {
  enable = false,
  disable = false,
}

---@private
---@type table<integer, string>
Module.methods = {}

---@private
---@type table<integer, string>
Module.expressions = {}

---called from state on setup
---@param config ts.mod.fold_text.Config
function Module.setup(config)
  Module.config = config
end

---@return string
function Module.name()
  return 'fold_text'
end

---@param ctx ts.mod.Context
---@return boolean
function Module.enabled(ctx)
  local util = require('treesitter-modules.lib.util')
  return util.enabled(Module.config, ctx)
end

---@param ctx ts.mod.Context
function Module.attach(ctx)
  vim.opt_local.foldmethod = 'expr'
  vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
end

---@param ctx ts.mod.Context
function Module.detach(ctx)
  -- NOTE: We use global setup when detaching because `buf`
  -- could be open in a different or multiple windows
  -- so trying to recover window option is tricky.
  -- Better to always fallback to a known value.
  vim.opt_local.foldmethod = vim.go.foldmethod
  vim.opt_local.foldexpr = vim.go.foldexpr
end

return Module

