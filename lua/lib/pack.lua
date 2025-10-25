--[[
-- nvim 0.12.0 wrapper for builtin package manager
-- to allow lazy load of plugins using events, autocmd, or keymaps
--]]

local default = 'https://github.com/'
-- local group = vim.api.nvim_create_augroup('pack-load-cmd', { clear = true })
local lazy_start = 'LazyStart'

-- local group = vim.api.nvim_create_augroup('LoadPluginAutoCmd', { clear = true })

-- local pack_group = vim.api.nvim_create_augroup('pack-update', { clear = true })
-- vim.api.nvim_create_autocmd('PackChanged', {
--   group = pack_group,
--   callback = function (ev)
--     if ev.data.kind == 'update' and ev.data.spec.name == '' then
--
--     end
--
--   end
-- })

---@class PluginLoadSpec: vim.pack.Spec
---@field lazy boolean

---Ensure entry is a spec object
---@param url string
---@return PluginLoadSpec
local to_spec = function (url)
  return {
    src = url,
  }
end

local loaded = false

if not loaded then
  loaded = true
  vim.api.nvim_create_autocmd('UIEnter', {
    callback = vim.schedule_wrap(function ()
      vim.api.nvim_exec_autocmds('User', { pattern = lazy_start })
    end)
  })
end

---@param plugins (string|PluginLoadSpec)[]
local function load(plugins)

  -- Add 'github.com' prefix if not present
  for i, plugin in ipairs(plugins) do
    if type(plugin) == "string" then
      plugin = to_spec(plugin)
      plugins[i] = plugin
    end

    local _, matches = plugin.src:gsub('^http', '.')
    if matches == 0 then
      plugin.src = default .. vim.trim(plugin.src)
    end
  end

  vim.pack.add(plugins, {
    load = function(plugin)
      local local_group = vim.api.nvim_create_augroup('pack-load-cmd-'..plugin.spec.name, { clear = true })
      local data = plugin.spec.data or {}
      -- If spec is lazy, do not load immediately
      -- plugin should be loaded until manually required
      -- or loaded with vim.cmd.pack()
      -- or when a trigger is fired
      local lazy_load = plugin.spec.lazy or false
      local package_loaded = false

      local do_clear = function ()
        -- Event trigger and FileType trigger cleanup
        if data.event then
          -- Delete all autocmd in the local group
          pcall(vim.api.nvim_clear_autocmds, { group = local_group })
        end

        -- Command trigger cleanup
        if data.cmd then
          -- Delete placeholder command
          pcall(vim.api.nvim_del_user_command, data.cmd)
        end

        -- Keymap trigger cleanup
        if data.keys then
          local mode, lhs = data.keys[1], data.keys[2]
          -- Delete placeholder mapping
          pcall(vim.keymap.del, mode, lhs)
        end
      end

      local do_load = function ()
        -- Prevent double calling from loaded packages
        if package_loaded then
          return
        end

        pcall(do_clear)

        vim.cmd.packadd(plugin.spec.name)
        if data.config then
          local succ, err = pcall(data.config, plugin)
          if not succ then
            vim.notify(
              ('[Pack] Could not load plugin: %s'):format(err),
              vim.log.levels.ERROR)
          end
        end
        package_loaded = true
      end

      -- Event trigger
      if data.event then
        if data.event == lazy_start then
          vim.api.nvim_create_autocmd('User', {
            group = local_group,
            once = true,
            pattern = lazy_start,
            callback = do_load,
          })
        else
          vim.api.nvim_create_autocmd(data.event, {
            group = local_group,
            once = true,
            pattern = data.pattern or '*',
            callback = do_load,
          })
        end

        lazy_load = true
      end

      -- FileType trigger
      if data.ft then
        vim.api.nvim_create_autocmd('FileType', {
          group = local_group,
          once = true,
          pattern = data.ft,
          callback = do_load,
        })

        lazy_load = true
      end

      -- Command trigger
      if data.cmd then
        vim.api.nvim_create_user_command(data.cmd, function(cmd_args)
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
            reg = cmd_args.reg,
          }, {})
        end, {
          nargs = data.nargs,
          range = data.range,
          bang = data.bang,
          complete = data.complete,
          count = data.count,
          register = data.register,
          bar = data.bar,
        })

        lazy_load = true
      end

      -- Keymap trigger
      if data.keys then
        local mode, lhs = data.keys[1], data.keys[2]
        vim.keymap.set(mode, lhs, function()
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
