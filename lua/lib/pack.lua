--[[
-- nvim 0.12.0 wrapper for builtin package manager
-- to allow lazy load of plugins using events, autocmd, or keymaps
--]]

local group = vim.api.nvim_create_augroup('LoadPluginAutoCmd', { clear = true })

---@class PluginLoadSpec: vim.pack.Spec
---@field lazy boolean

---@param plugins (string|vim.pack.Spec)[]
local function load(plugins)
  vim.pack.add(plugins, {
    load = function(plugin)
      local data = plugin.spec.data or {}
      local lazy_load = plugin.spec.lazy or false

      local do_load = function ()
        vim.cmd.packadd(plugin.spec.name)
        if data.config then
          data.config(plugin)
        end
      end

      -- Event trigger
      if data.event then
        vim.api.nvim_create_autocmd(data.event, {
          group = group,
          once = true,
          pattern = data.pattern or '*',
          callback = do_load,
        })

        lazy_load = true
      end

      -- Command trigger
      if data.cmd then
        vim.api.nvim_create_user_command(data.cmd, function(cmd_args)
          -- Delete placeholder keymap
          pcall(vim.api.nvim_del_user_command, data.cmd)

          -- First load the plugin
          do_load()

          -- Then call the command
          vim.api.nvim_cmd({
            cmd = data.cmd,
            args = cmd_args.fargs,
            bang = cmd_args.bang,
            nargs = cmd_args.nargs,
            range = cmd_args.range ~= 0 and { cmd_args.line1, cmd_args.line2 } or nil,
            count = cmd_args.count ~= -1 and cmd_args.count or nil,
          }, {})
        end, {
          nargs = data.nargs,
          range = data.range,
          bang = data.bang,
          complete = data.complete,
          count = data.count,
        })

        lazy_load = true
      end

      -- Keymap trigger
      if data.keys then
        local mode, lhs = data.keys[1], data.keys[2]
        vim.keymap.set(mode, lhs, function()
          -- Delete placeholder mapping
          vim.keymap.del(mode, lhs)

          -- Load the plugin
          do_load()

          -- Then feed the key sequence
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), 'm', false)
        end, { desc = data.desc })

        lazy_load = true
      end

      if lazy_load then
        return
      end

      -- Immediately load plugin if not lazy loaded
      do_load()
    end,
  })
end

--- Sample
-- load({
--   {
--     src = 'https://github.com/lewis6991/gitsigns.nvim',
--     data = {
--       event = { 'BufReadPre', 'BufNewFile' },
--       config = function()
--         require('gitgins.nvim-config')
--       end,
--     },
--   },
--   {
--     src = 'https://github.com/echasnovski/mini.splitjoin',
--     data = {
--       keys = { 'n', 'gS' },
--       config = function()
--         require('mini.splitjoin').setup({})
--       end,
--     },
--   },
--   {
--     src = 'https://github.com/ibhagwan/fzf-lua',
--     data = {
--       keys = { 'n', '<leader>f' },
--       cmd = 'FzfLua',
--       config = function()
--         require('fzf-lua-config')
--       end,
--     },
--   },
--   {
--     src = 'https://github.com/williamboman/mason.nvim',
--     data = {
--       cmd = 'Mason',
--       config = function()
--         require('mason').setup({})
--       end,
--     },
--   },
-- })

return {
  load = load
}
