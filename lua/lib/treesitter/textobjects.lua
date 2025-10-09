---@class (exact) ts.mod.textobjects.Config: ts.mod.module.Config

---@class ts.mod.textobjects: ts.mod.Module
---@field private config ts.mod.textobjects.Config
local Module = {}

---@type ts.mod.textobjects.Config
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
---@param config ts.mod.textobjects.Config
function Module.setup(config)
  Module.config = config
end

---@return string
function Module.name()
  return 'textobjects'
end

---@param ctx ts.mod.Context
---@return boolean
function Module.enabled(ctx)
  local util = require('treesitter-modules.lib.util')
  return util.enabled(Module.config, ctx)
end

local xo = { 'x', 'o' }
local nxo = { 'n', 'x', 'o' }

--- Defines a |mapping| of |keycodes| to a function or keycodes.
---
--- Examples:
---
--- ```lua
--- -- Map "x" to a Lua function:
--- vim.keymap.set('n', 'x', function() print("real lua function") end)
--- -- Map "<leader>x" to multiple modes for the current buffer:
--- vim.keymap.set({'n', 'v'}, '<leader>x', vim.lsp.buf.references, { buffer = true })
--- -- Map <Tab> to an expression (|:map-<expr>|):
--- vim.keymap.set('i', '<Tab>', function()
---   return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
--- end, { expr = true })
--- -- Map "[%%" to a <Plug> mapping:
--- vim.keymap.set('n', '[%%', '<Plug>(MatchitNormalMultiBackward)')
--- ```
---
---@param mode string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
local safeKeymapSet = function (mode, lhs, rhs, opts)
  pcall(vim.keymap.set, mode, lhs, rhs, opts)
end

--- Remove an existing mapping.
--- Examples:
---
--- ```lua
--- vim.keymap.del('n', 'lhs')
---
--- vim.keymap.del({'n', 'i', 'v'}, '<leader>w', { buffer = 5 })
--- ```
---
---@param mode string|string[]
---@param lhs string
---@param opts? vim.keymap.del.Opts
local safeKeymapDel = function (mode, lhs, opts)
  pcall(vim.keymap.del, mode, lhs, opts)
end

---@param ctx ts.mod.Context
function Module.attach(ctx)
  -- keymaps "Select"
  safeKeymapSet(xo, 'agb', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@block.outer', 'textobjects')
  end, { desc = '[TS] Select a block', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'igb', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@block.inner', 'textobjects')
  end, { desc = '[TS] Select inner function', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'af', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
  end, { desc = '[TS] Select a function', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'if', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
  end, { desc = '[TS] Select inner function', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'ac', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
  end, { desc = '[TS] Select a class', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'ic', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
  end, { desc = '[TS] Select inner part of a class region', buffer = ctx.buf, noremap = true })
  safeKeymapSet(xo, 'as', function()
    -- You can also use captures from other query groups like `locals.scm`
    require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
  end, { desc = '[TS] Select language scope', buffer = ctx.buf, noremap = true })


  -- keymaps "Move"
  -- goto next start
  safeKeymapSet(nxo, ']m', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
  end, { desc = '[TS] Next function start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, ']]', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
  end, { desc = '[TS] Next class start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, ']k', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@block.*', 'textobjects')
  end, { desc = '[TS] Next block start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, ']C', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@comment.outer', 'textobjects')
  end, { desc = '[TS] Next comment start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, ']f', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@local.scope', 'locals')
  end, { desc = '[TS] Next scope', buffer = ctx.buf, noremap = true })

  -- goto next end
  safeKeymapSet(nxo, ']M', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
  end, { desc = '[TS] Next function end', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '][', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
  end, { desc = '[TS] Next class end', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, ']K', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@block.outer', 'textobjects')
  end, { desc = '[TS] Next block end', buffer = ctx.buf, noremap = true })

  -- goto previous start
  safeKeymapSet(nxo, '[m', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
  end, { desc = '[TS] Previous function start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[[', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
  end, { desc = '[TS] Previous class start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[k', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@block.*', 'textobjects')
  end, { desc = '[TS] Previous block start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[C', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@comment.outer', 'textobjects')
  end, { desc = '[TS] Previous comment start', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[f', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@local.scope', 'locals')
  end, { desc = '[TS] Previous scope', buffer = ctx.buf, noremap = true })

  -- goto previous end
  safeKeymapSet(nxo, '[M', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
  end, { desc = '[TS] Previous function end', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[]', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
  end, { desc = '[TS] Previous class end', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[K', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@block.outer', 'textobjects')
  end, { desc = '[TS] Previous block end', buffer = ctx.buf, noremap = true })


  -- Go to either the start or the end, whichever is closer.
  -- Use if you want more granular movements
  safeKeymapSet(nxo, ']x', function()
    require('nvim-treesitter-textobjects.move').goto_next('@conditional.outer', 'textobjects')
  end, { desc = '[TS] Next start/end', buffer = ctx.buf, noremap = true })
  safeKeymapSet(nxo, '[x', function()
    require('nvim-treesitter-textobjects.move').goto_previous('@conditional.outer', 'textobjects')
  end, { desc = '[TS] Previous start/end', buffer = ctx.buf, noremap = true })
end

---@param ctx ts.mod.Context
function Module.detach(ctx)
  -- keymaps "Select"
  safeKeymapDel(xo, 'agb', { buffer = ctx.buf })
  safeKeymapDel(xo, 'igb', { buffer = ctx.buf })
  safeKeymapDel(xo, 'af', { buffer = ctx.buf })
  safeKeymapDel(xo, 'if', { buffer = ctx.buf })
  safeKeymapDel(xo, 'ac', { buffer = ctx.buf })
  safeKeymapDel(xo, 'ic', { buffer = ctx.buf })
  safeKeymapDel(xo, 'as', { buffer = ctx.buf })


  -- keymaps "Move"
  -- goto next start
  safeKeymapDel(nxo, ']m', { buffer = ctx.buf })
  safeKeymapDel(nxo, ']]', { buffer = ctx.buf })
  safeKeymapDel(nxo, ']k', { buffer = ctx.buf })
  safeKeymapDel(nxo, ']C', { buffer = ctx.buf })
  safeKeymapDel(nxo, ']f', { buffer = ctx.buf })

  -- goto next end
  safeKeymapDel(nxo, ']M', { buffer = ctx.buf })
  safeKeymapDel(nxo, '][', { buffer = ctx.buf })
  safeKeymapDel(nxo, ']K', { buffer = ctx.buf })

  -- goto previous start
  safeKeymapDel(nxo, '[m', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[[', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[k', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[C', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[f', { buffer = ctx.buf })

  -- goto previous end
  safeKeymapDel(nxo, '[M', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[]', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[K', { buffer = ctx.buf })

  -- go to either
  safeKeymapDel(nxo, ']x', { buffer = ctx.buf })
  safeKeymapDel(nxo, '[x', { buffer = ctx.buf })
end

return Module
