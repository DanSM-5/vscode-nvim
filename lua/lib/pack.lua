--[[
-- nvim 0.12.0 wrapper for builtin package manager
-- to allow lazy load of plugins using events, autocmd, or keymaps
--]]

-- local default = 'https://github.com/'

local github_fmt = 'https://github.com/%s'
-- local group = vim.api.nvim_create_augroup('pack-load-cmd', { clear = true })
local lazy_start = 'LazyStart'

---@alias pack.load.plug { load: fun(); clear: fun(); data: pack.data.specInt; loaded: boolean; name: string; }
---Table containing plugins data for internal use
---@alias pack.load.tbl table<string, pack.load.plug?>

---@type pack.load.tbl
local load_tbl = {}

-- local group = vim.api.nvim_create_augroup('LoadPluginAutoCmd', { clear = true })

local pack_group = vim.api.nvim_create_augroup('pack_group', { clear = true })

---:h PackChanged
---@class pack.build.data
---@field active boolean Whether plugin was added via vim.pack.add
---@field kind 'install' | 'update' | 'delete' kind of package change
---@field spec { src: string, name: string, version: string|vim.VersionRange|nil, data: pack.plugin.loadSpec }
---@field path string

-- Needed for completion when adding a spec to the array of plugins
---@alias pack.load.event vim.api.keyset.events|'LazyStart'
---@alias pack.load.events pack.load.event|pack.load.event[]
---@alias pack.load.build_hook string|string[]|fun(data: pack.build.data)

---@class pack.plugin.cmd_opts
---@field cmd string Command trigger
---@field nargs? string number of arguments for command trigger. See `:h nargs`.
---@field range? integer range for command trigger.
---@field bang? boolean whether to accept bang for command trigger.
---@field count? integer count for command trigger.
---@field register? boolean optional register for command trigger.
---@field bar? boolean allow usage of bar `|` in command trigger.
---@field desc? string optional description for command trigger.
---@field complete? fun(alead: string, cmd_line: string, pos: number): string[] optional description for triggers

---@alias pack.data.cmd string|string[]|pack.plugin.cmd_opts|pack.plugin.cmd_opts[]
---@alias pack.data.keys { modes: string|string[], lhs: string } key format

---@class pack.data.spec
---@field lazy? boolean Whether to lazy load the plugin or not.
---@field event? pack.load.events Event trigger.
---@field pattern? string patter for event trigger autocmd. '*' by default.
---@field ft? string|string[] filetype pattern for FileType autocmd.
---@field cmd? pack.data.cmd Command trigger.
---@field keys? pack.data.keys|pack.data.keys[]
---@field desc? string optional description for triggers
---@field config? fun(data: pack.plugin) Config function for plugin.
---@field deps? string|string[] Ensure dependencies are loaded. This is not a full spec, all dependencies need to be added at the top object and this just reference them from it
---@field build? pack.load.build_hook Build hook
---@field buildPre? pack.load.build_hook PreBuild hook
---@field init? fun(data: pack.plugin) Like config but before plugin is loaded

-- Hack to avoid typing errors when matching a string agains the events type
-- by collapsing them into just string or 'LazyStart' for handling it internally
---@alias pack.data.str_evt (string|'LazyStart')
---@alias pack.data.str_evt_arr pack.data.str_evt[]

---@class pack.data.specInt: pack.data.spec
---@field event? (pack.data.str_evt)|(pack.data.str_evt_arr)

---@class pack.plugin.loadSpec: vim.pack.Spec
---@field data? pack.data.spec

---@alias pack.plugin { spec: pack.plugin.loadSpec; path: string; }

---Ensure entry is a spec object
---@param url string
---@return pack.plugin.loadSpec
local to_spec = function(url)
  return {
    src = url,
  }
end

local loaded = false

if not loaded then
  loaded = true
  vim.api.nvim_create_autocmd('UIEnter', {
    group = pack_group,
    callback = vim.schedule_wrap(function()
      vim.api.nvim_exec_autocmds('User', { pattern = lazy_start })
    end),
  })

  ---Build hook function
  ---@param data pack.build.data
  ---@param buildType 'buildPre'|'build'
  local function build_hook(data, buildType)
    local spec = load_tbl[data.spec.name]
    if not spec then
      vim.notify(('[:Pack] could not found spec for "%s"'):format(data.spec.name))
      return
    end

    ---@type pack.load.build_hook?
    local hook = spec.data[buildType]

    -- No hook, skip
    if not hook then
      return
    end

    if not data.active then
      spec.load()
    end

    -- Delegate build to caller
    if type(hook) == 'function' then
      return hook(data)
    end

    -- Call if provided string is a vim command
    if type(hook) == 'string' and vim.startswith(hook, ':') then
      local cmd = hook:gsub('^:', '')

      -- Then call the command
      vim.api.nvim_cmd({
        cmd = cmd,
      }, {})
      return
    end

    -- Ensure hook is string
    hook = vim.islist(hook) and hook or vim.split(hook --[[@as string]], ' ', { plain = true, trimempty = true })
    ---@cast hook string[]
    vim.schedule(function()
      -- local package_name = vim.fn.fnamemodify(data.spec.src, ':t')
      local package_name = data.spec.name
      vim.notify(('Building %s...'):format(package_name), vim.log.levels.INFO)
      vim.system(hook, { cwd = data.path }, function(result)
        local success = result.code == 0
        local log_level = success and vim.log.levels.INFO or vim.log.levels.ERROR
        local message = success and 'successful' or 'failed'
        vim.notify(('Build %s for %s'):format(message, package_name), log_level)
      end)
    end)
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    group = pack_group,
    callback = function(args)
      ---@type pack.build.data
      local data = args.data
      if vim.tbl_contains({ 'install', 'update' }, data.kind) then
        build_hook(data, 'build')
      end
    end,
  })
  vim.api.nvim_create_autocmd('PackChangedPre', {
    group = pack_group,
    callback = function(args)
      ---@type pack.build.data
      local data = args.data
      if vim.tbl_contains({ 'install', 'update' }, data.kind) then
        build_hook(data, 'buildPre')
      end
    end,
  })
end

---Run safely a callback such as `config` or `init`
---@param cb fun(data: pack.plugin) callback to run
---@param plugin pack.plugin plugin spec to pass to callback
---@param cb_type 'init'|'config' type of callback
local function run_cb(cb, plugin, cb_type)
  local succ, err = pcall(cb, plugin)
  if not succ then
    vim.notify(err, vim.log.levels.ERROR)
    vim.notify(
      ('[Pack] Could failed to run "%" for plugin: %s'):format(cb_type, plugin.spec.name),
      vim.log.levels.ERROR
    )
  end
end

--- Ensure plugin entries match the spec
---@param plugins (string|pack.plugin.loadSpec)[]
---@return pack.plugin.loadSpec[]
local function preprocess(plugins)
  for i, plugin in ipairs(plugins) do
    if type(plugin) == 'string' then
      plugin = to_spec(plugin)
      plugins[i] = plugin
    end

    local _, matches = plugin.src:gsub('^http', '.')
    -- Add 'github.com' prefix if not present
    if matches == 0 then
      plugin.src = github_fmt:format(vim.trim(plugin.src))
    end

    -- Ensure all plugins have data
    plugin.data = plugin.data or {}
  end

  return plugins
end

--- Load list of plugins
---@param plugins (string|pack.plugin.loadSpec)[]
local function load(plugins)
  -- Preprocess plugins to match expected spec
  plugins = preprocess(plugins)

  -- Load plugins
  vim.pack.add(plugins, {
    load = function(plugin)
      local spec_name = vim.trim(plugin.spec.name)
      local group_name = ('pack-load-cmd_%s'):format(
        (spec_name and spec_name ~= '') and spec_name or plugin.path:gsub(vim.pesc('/'), '-')
      )
      local local_group = vim.api.nvim_create_augroup(group_name, { clear = true })
      ---@type pack.data.specInt
      local data = plugin.spec.data or {}
      -- If spec is lazy, do not load immediately
      -- plugin should be loaded until manually required
      -- or loaded with vim.cmd.pack()
      -- or when a trigger is fired
      local lazy_load = data.lazy or false
      local package_loaded = false
      -- Flag to attempt avoiding a recursive load chain
      local loading_deps = false

      --- Function that clears handlers
      local do_clear = function()
        -- Event trigger and FileType trigger cleanup
        if data.event then
          -- Delete all autocmd in the local group
          pcall(vim.api.nvim_clear_autocmds, { group = local_group })
          pcall(vim.api.nvim_create_augroup, group_name, { clear = true })
        end

        -- Command trigger cleanup
        if data.cmd then
          local cmds = vim.islist(data.cmd) and data.cmd or { data.cmd }
          ---@cast cmds string[]|pack.plugin.cmd_opts[]

          for _, cmd in ipairs(cmds) do
            local cmd_str = type(cmd) == 'string' and cmd or cmd.cmd
            pcall(vim.api.nvim_del_user_command, cmd_str)
          end
        end

        -- Keymap trigger cleanup
        if data.keys then
          local keys = vim.islist(data.keys) and data.keys or { data.keys }
          ---@cast keys pack.data.keys[]

          for _, keymap in ipairs(keys) do
            local modes, lhs = keymap.modes, keymap.lhs
            -- Delete placeholder mapping
            pcall(vim.keymap.del, modes, lhs)
          end
        end
      end

      --- Function that load the plugin.
      --- On the very basic config, it just calls `packadd <pname>`
      local do_load = function()
        -- Prevent double calling from loaded packages
        if package_loaded or loading_deps then
          return
        end

        pcall(do_clear)

        local deps = data.deps
        if deps then
          ---@cast deps string[]
          deps = vim.isarray(deps) and deps or { deps }

          loading_deps = true

          for _, dep in ipairs(deps) do
            if load_tbl[dep] then
              pcall(load_tbl[dep].load)
            end
          end

          loading_deps = false
        end

        ---@cast plugin pack.plugin

        -- Run initialization and configuration
        if data.init then
          run_cb(data.config, plugin, 'init')
        end
        vim.cmd.packadd(plugin.spec.name)
        if data.config then
          run_cb(data.config, plugin, 'config')
        end

        -- cleanup state
        package_loaded = true
        load_tbl[plugin.spec.name].loaded = true
      end

      -- Store useful refs
      load_tbl[plugin.spec.name] = { load = do_load, clear = do_clear, data = data, loaded = false, name = plugin.spec.name }

      -- Event trigger
      if data.event then
        ---@type pack.data.str_evt_arr
        local events = type(data.event) == 'string' and { data.event } or data.event --[[@as pack.data.str_evt_arr]]

        ---@type string[]
        local filtered_evts = vim
          .iter(events)
          :filter(function(evt)
            return evt ~= lazy_start
          end)
          :totable()

        --- If LazyStart got filtered out
        local has_lazy_start = #events > #filtered_evts

        if has_lazy_start then
          vim.api.nvim_create_autocmd('User', {
            group = local_group,
            once = true,
            pattern = lazy_start,
            callback = do_load,
            desc = data.desc,
          })
        end

        if #filtered_evts > 0 then
          vim.api.nvim_create_autocmd(filtered_evts, {
            group = local_group,
            once = true,
            pattern = data.pattern or '*',
            callback = do_load,
            desc = data.desc,
          })
        end

        lazy_load = true
      end

      -- FileType trigger
      if data.ft then
        local fts = vim.islist(data.ft) and data.ft or { data.ft }
        ---@cast fts string[]
        for _, ft in ipairs(fts) do
          vim.api.nvim_create_autocmd('FileType', {
            group = local_group,
            once = true,
            pattern = ft,
            callback = do_load,
            desc = data.desc,
          })
        end

        lazy_load = true
      end

      -- Command trigger
      if data.cmd then
        local cmds = vim.islist(data.cmd) and data.cmd or { data.cmd }
        ---@cast cmds string[]|pack.plugin.cmd_opts[]

        for _, cmd in ipairs(cmds) do
          ---@type pack.plugin.cmd_opts
          local cmd_opts = type(cmd) == 'string'
              and {
                cmd = cmd,
                desc = ('[Pack] Placeholder command trigger for %s'):format(plugin.spec.name),
              } --[[@as pack.plugin.cmd_opts]]
            or cmd

          vim.api.nvim_create_user_command(cmd_opts.cmd, function(cmd_args)
            -- First load the plugin
            do_load()

            ---@type vim.api.keyset.cmd
            local _cmd = {
              cmd = cmd_opts.cmd,
              args = cmd_args.fargs,
              bang = cmd_args.bang,
              nargs = cmd_args.nargs,
              range = cmd_args.range ~= 0 and { cmd_args.line1, cmd_args.line2 } or nil,
              count = cmd_args.count ~= -1 and cmd_args.count or nil,
              -- reg = cmd_args.reg,
            }

            -- Then call the command
            vim.api.nvim_cmd(_cmd, {})
          end, {
            nargs = cmd_opts.nargs or '*',
            range = cmd_opts.range,
            bang = cmd_opts.bang,
            count = cmd_opts.count,
            register = cmd_opts.register,
            bar = cmd_opts.bar,
            desc = cmd_opts.desc,
            ---complete = cmd_opts.complete,
            ---completion function
            ---@param arg_lead string
            ---@param cmd_line string
            ---@param pos number
            ---@return string[]
            complete = function(arg_lead, cmd_line, pos)
              -- upon requesting completion, load the real plugin
              -- to allow real completion to take effect
              do_load()
              return cmd_opts.complete and cmd_opts.complete(arg_lead, cmd_line, pos) or { arg_lead } -- return current?
            end,
          })
        end

        lazy_load = true
      end

      -- Keymap trigger
      if data.keys then
        local keys = vim.islist(data.keys) and data.keys or { data.keys }
        ---@cast keys pack.data.keys[]

        for _, keymap in ipairs(keys) do
          local modes, lhs = keymap.modes, keymap.lhs

          -- Set keymap trigger
          vim.keymap.set(modes, lhs, function()
            -- Load the plugin
            do_load()

            -- Then feed the key sequence
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), 'm', false)
          end, { desc = data.desc or ('[pack] keymap trigger for %s'):format(plugin.spec.name) })
        end

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

---Install the list of plugins
---@param plugins (string|vim.pack.Spec)[]
local function pack_install(plugins)
  vim.pack.add(plugins, { load = true, confirm = false })
end

---Update the list of plugins
---if plugins is empty array or nil it will update all plugins as per
---vim.pack.update behavior
---@param plugins string[]|nil
---@param opts? { force?: boolean }
local function pack_update(plugins, opts)
  opts = vim.tbl_deep_extend('force', { force = false }, opts or {})

  -- vim.pack.update will update all plugins if passed an empty array
  -- this take advantage of that and sends nil if called with empty array
  plugins = plugins and #plugins == 0 and nil or plugins
  vim.pack.update(plugins, { force = opts.force })
end

---Remove the list of plugins
---@param plugins string[] List of plugin names
---@param opts? { force?: boolean } if it should confirm or force
local function pack_delete(plugins, opts)
  opts = vim.tbl_deep_extend('force', { force = false }, opts or {})
  vim.pack.del(plugins, opts)
  for _, plugin in ipairs(plugins) do
    local p = load_tbl[plugin]
    if p then
      pcall(p.clear)
      load_tbl[plugin] = nil
    end
  end
end

---Restore plugins to match lockfile
---@param plugins? string[] Not used. Can be only listed ones 🤔
local function pack_restore(plugins)
  vim.pack.update(nil, { target = 'lockfile' })
end

---Get iter with pack's package names
---@return string[]
local function get_pack_names()
  return vim
    .iter(vim.pack.get())
    :map(function(pack)
      return pack.spec.name
    end)
    :totable()
end

---@type table<fun(), any>
local cache = {}

---Get momeoized value
---@generic T : fun()
---@param time integer ms to cache
---@param fn T function to memoize
---@return T
local function memoized(time, fn)
  -- TODO: validate args as part of the memo
  return function(...)
    local stored = cache[fn]
    if stored then
      return stored
    end

    local output = fn(...)
    cache[fn] = output
    local timer = vim.uv.new_timer() --[[@as uv.uv_timer_t]]
    timer:start(time, 0, function()
      timer:stop()
      cache[fn] = nil
    end)

    return output
  end
end

-- Cache package names for 5 minutes
local get_pack_names_memo = memoized(300000, get_pack_names)

---Complete the package name
---@param arg_lead string
---@return string[]
local function complete_packages(arg_lead)
  arg_lead = arg_lead or ''
  local names = get_pack_names_memo()
  return vim
    .iter(names)
    :filter(function(name)
      return vim.startswith(name, arg_lead)
    end)
    :totable()
end

return {
  load = load,
  load_tbl = load_tbl,
  update = pack_update,
  install = pack_install,
  delete = pack_delete,
  restore = pack_restore,
  complete_packages = complete_packages,
}
