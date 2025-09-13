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

---@param ctx ts.mod.Context
function Module.attach(ctx)
  -- keymaps "Select"
  vim.keymap.set(xo, 'agb', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@block.outer', 'textobjects')
  end, { desc = '[TS] Select a block', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'igb', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@block.inner', 'textobjects')
  end, { desc = '[TS] Select inner function', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'af', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
  end, { desc = '[TS] Select a function', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'if', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
  end, { desc = '[TS] Select inner function', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'ac', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
  end, { desc = '[TS] Select a class', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'ic', function()
    require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
  end, { desc = '[TS] Select inner part of a class region', buffer = ctx.buf, noremap = true })
  vim.keymap.set(xo, 'as', function()
    -- You can also use captures from other query groups like `locals.scm`
    require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
  end, { desc = '[TS] Select language scope', buffer = ctx.buf, noremap = true })


  -- keymaps "Move"
  -- goto next start
  vim.keymap.set(nxo, ']m', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
  end, { desc = '[TS] Next function start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, ']]', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
  end, { desc = '[TS] Next class start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, ']k', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@block.*', 'textobjects')
  end, { desc = '[TS] Next block start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, ']C', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@comment.outer', 'textobjects')
  end, { desc = '[TS] Next comment start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, ']f', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@local.scope', 'locals')
  end, { desc = '[TS] Next scope', buffer = ctx.buf, noremap = true })

  -- goto next end
  vim.keymap.set(nxo, ']M', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
  end, { desc = '[TS] Next function end', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '][', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
  end, { desc = '[TS] Next class end', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, ']K', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@block.outer', 'textobjects')
  end, { desc = '[TS] Next block end', buffer = ctx.buf, noremap = true })

  -- goto previous start
  vim.keymap.set(nxo, '[m', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
  end, { desc = '[TS] Previous function start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[[', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
  end, { desc = '[TS] Previous class start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[k', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@block.*', 'textobjects')
  end, { desc = '[TS] Previous block start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[C', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@comment.outer', 'textobjects')
  end, { desc = '[TS] Previous comment start', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[f', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@local.scope', 'locals')
  end, { desc = '[TS] Previous scope', buffer = ctx.buf, noremap = true })

  -- goto previous end
  vim.keymap.set(nxo, '[M', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
  end, { desc = '[TS] Previous function end', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[]', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
  end, { desc = '[TS] Previous class end', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[K', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@block.outer', 'textobjects')
  end, { desc = '[TS] Previous block end', buffer = ctx.buf, noremap = true })


  -- Go to either the start or the end, whichever is closer.
  -- Use if you want more granular movements
  vim.keymap.set(nxo, ']x', function()
    require('nvim-treesitter-textobjects.move').goto_next('@conditional.outer', 'textobjects')
  end, { desc = '[TS] Next start/end', buffer = ctx.buf, noremap = true })
  vim.keymap.set(nxo, '[x', function()
    require('nvim-treesitter-textobjects.move').goto_previous('@conditional.outer', 'textobjects')
  end, { desc = '[TS] Previous start/end', buffer = ctx.buf, noremap = true })
end

---@param ctx ts.mod.Context
function Module.detach(ctx)
  -- keymaps "Select"
  vim.keymap.del(xo, 'agb', { buffer = ctx.buf })
  vim.keymap.del(xo, 'igb', { buffer = ctx.buf })
  vim.keymap.del(xo, 'af', { buffer = ctx.buf })
  vim.keymap.del(xo, 'if', { buffer = ctx.buf })
  vim.keymap.del(xo, 'ac', { buffer = ctx.buf })
  vim.keymap.del(xo, 'ic', { buffer = ctx.buf })
  vim.keymap.del(xo, 'as', { buffer = ctx.buf })


  -- keymaps "Move"
  -- goto next start
  vim.keymap.del(nxo, ']m', { buffer = ctx.buf })
  vim.keymap.del(nxo, ']]', { buffer = ctx.buf })
  vim.keymap.del(nxo, ']k', { buffer = ctx.buf })
  vim.keymap.del(nxo, ']C', { buffer = ctx.buf })
  vim.keymap.del(nxo, ']f', { buffer = ctx.buf })

  -- goto next end
  vim.keymap.del(nxo, ']M', { buffer = ctx.buf })
  vim.keymap.del(nxo, '][', { buffer = ctx.buf })
  vim.keymap.del(nxo, ']K', { buffer = ctx.buf })

  -- goto previous start
  vim.keymap.del(nxo, '[m', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[[', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[k', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[C', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[f', { buffer = ctx.buf })

  -- goto previous end
  vim.keymap.del(nxo, '[M', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[]', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[K', { buffer = ctx.buf })

  -- go to either
  vim.keymap.del(nxo, ']x', { buffer = ctx.buf })
  vim.keymap.del(nxo, '[x', { buffer = ctx.buf })
end

return Module
