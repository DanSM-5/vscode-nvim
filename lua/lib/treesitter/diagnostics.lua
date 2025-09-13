---@class (exact) ts.mod.fold.Config: ts.mod.module.Config

---@class ts.mod.Fold: ts.mod.Module
---@field private config ts.mod.fold.Config
local Module = {}

---@type ts.mod.fold.Config
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
---@param config ts.mod.fold.Config
function Module.setup(config)
  Module.config = config
end

---@return string
function Module.name()
  return 'diagnostics'
end

---@param ctx ts.mod.Context
---@return boolean
function Module.enabled(ctx)
  if vim.g.vscode == 1 then
    -- Known bad filetypes
    if vim.tbl_contains({ 'log' }, ctx.language) then
      return false
    end

    -- check if remote buffer
    local remote = require('utils.diagnostics_vscode').is_remote(ctx.buf)
    if (not remote) and (vim.fn.filereadable(vim.fn.bufname(ctx.buf)) == 0) then
      return false
    end
  end

  local util = require('treesitter-modules.lib.util')
  return util.enabled(Module.config, ctx)
end

---@param ctx ts.mod.Context
function Module.attach(ctx)
  require('utils.diagnostics_vscode').start_ts_diagnostics(ctx.buf)
end

---@param ctx ts.mod.Context
function Module.detach(ctx)
  require('utils.diagnostics_vscode').stop_ts_diagnostics(ctx.buf)
end

return Module
