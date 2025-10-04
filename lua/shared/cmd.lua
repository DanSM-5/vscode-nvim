--- Utility functions

---Get the matching value from the a list
---@param options string[]
---@param value string
---@return string[]
local function get_matched(options, value)
  local matched = vim.tbl_filter(function(option)
    local _, matches = string.gsub(option, value, '')
    return matches > 0
  end, options)

  return #matched > 0 and matched or options
end

---Callback function for TSModule commands
---@param module string
---@param state 'enable'|'disable'|''|nil
---@param switch boolean|nil
local ts_modules_callback = function(module, state, switch)
  -- local module = args[1]
  -- local state = args[2]

  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf })
  local lang = vim.treesitter.language.get_lang(filetype)

  -- Cannot proceed without language
  if not lang then
    return
  end

  local manager = require('treesitter-modules.core.manager')
  local modules = manager.modules
  local target_mod = require('utils.stdlib').find(function(mod)
    return mod.name() == module
  end, modules)

  if not target_mod then
    vim.notify(string.format('Module "%s" is not registered', module), vim.log.levels.WARN)
    return
  end

  -- Enable / disable logic
  local ctx = { buf = buf, language = lang }
  local set = manager.cache:get(buf)

  local disable_module = function()
    if set:has(module) then
      set:remove(module)
      target_mod.detach(ctx)
    end
    if switch then
      target_mod.disable = true
    end
  end
  local enable_module = function()
    if not set:has(module) then
      set:add(module)
      target_mod.attach(ctx)
    end
    if switch then
      target_mod.disable = false
    end
  end

  if state == 'enable' then
    enable_module()
  elseif state == 'disable' then
    disable_module()
  elseif state == '' or state == nil then
    if set:has(module) then
      disable_module()
    else
      enable_module()
    end
  end
end

---Get module names
---@return string[]
local ts_modules_get_names = function()
  local names = {}
  local ts_modules = require('treesitter-modules.core.manager').modules

  for _, mod in ipairs(ts_modules) do
    table.insert(names, mod.name())
  end

  return names
end

---Complete function for module names
---@param current string
---@return string[]
local ts_modules_complete_name = function(current)
  local names = ts_modules_get_names()
  if #current > 0 then
    return get_matched(names, current)
  end

  return names
end

---Change status of module 'on' / 'off'
---@param module string
---@param state 'on'|'off'
local ts_modules_switch = function(module, state)
  local manager = require('treesitter-modules.core.manager')
  local modules = manager.modules
  local target_mod = require('utils.stdlib').find(function(mod)
    return mod.name() == module
  end, modules)

  if not target_mod then
    vim.notify(string.format('Module "%s" is not registered', module), vim.log.levels.WARN)
    return
  end

  if state == 'on' then
    target_mod.disable = false
  elseif state == 'off' then
    target_mod.disable = true
  end
end

---Complete function for TS modules
---@param current string Leading command argument
---@param cmd string Current command line including command
---@param cur_pos integer Cursor position in cmd
---@return string[]
local ts_modules_complete_fn = function(current, cmd, cur_pos)
  if #vim.split(cmd, ' ') > 2 then
    return {}
  end

  return ts_modules_complete_name(current)
end

---

-- Clean search highlight (ctrl-l)
vim.api.nvim_create_user_command('CleanSearch', function()
  vim.cmd.nohlsearch()
end, { desc = 'Clean search highlight', bar = true })

-- Clean all carriage return symbols
vim.api.nvim_create_user_command('CleanCR', function()
  vim.cmd([[
    try
      silent exec '%s/\r$//g'
    catch
    endtry
  ]])
end, { desc = 'Clean carriage return characters', bar = true })

-- Clean all trailing spaces
vim.api.nvim_create_user_command('CleanTrailingSpaces', function()
  vim.cmd([[silent exec '%s/\s\+$//e']])
end, { desc = 'Clean empty characters at the end of the line', bar = true })

-- Repeatable move commands
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMove', function()
  require('utils.repeatable_move').repeat_last_move()
end, { desc = '[Repeatable] Repeat last move', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveOpposite', function()
  require('utils.repeatable_move').repeat_last_move_opposite()
end, { desc = '[Repeatable] Repeat last move opposite', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMoveNext', function()
  require('utils.repeatable_move').repeat_last_move_next()
end, { desc = '[Repeatable] Repeat last move in forward direction', bar = true, bang = true })
vim.api.nvim_create_user_command('TSTextobjectRepeatLastMovePrevious', function()
  require('utils.repeatable_move').repeat_last_move_previous()
end, { desc = '[Repeatable] Repeat last move in backward direction', bar = true, bang = true })

-- Maps normal, visual and o-pending at the same time
vim.api.nvim_create_user_command(
  'NXOnoremap',
  'nnoremap <args><Bar>xnoremap <args><Bar>onoremap <args>',
  { nargs = 1, desc = '[Nvim] Map normal, visual and operation pending' }
)
-- Make search consistent
vim.cmd.NXOnoremap([[<expr>n (v:searchforward ? 'n' : 'N').'zv']])
vim.cmd.NXOnoremap([[<expr>N (v:searchforward ? 'N' : 'n').'zv']])

-- Search in browser
vim.api.nvim_create_user_command('BSearch', function(args)
  local first = args.fargs[1]
  local engine = string.gsub(first, '@', '')
  local search = require('utils.browser_search')
  if string.sub(first, 1, 1) == '@' and search.is_valid_engine(engine) then
    search.search_browser(table.concat({ unpack(args.fargs, 2) }, ' '), engine)

    return
  end

  search.search_browser(table.concat(args.fargs, ' '))
end, {
  desc = 'Search in browser',
  bang = true,
  -- bar = true,
  nargs = '+',
  complete = function(current, cmd)
    -- Only complete first arg
    if #vim.split(cmd, ' ') > 2 then
      return
    end

    local engines = { '@google', '@bing', '@duckduckgo', '@wikipedia', '@brave', '@yandex', '@github' }
    if type(current) == 'string' and #current > 0 then
      return get_matched(engines, current)
    end

    return engines
  end,
})

-- Treesitter
vim.api.nvim_create_user_command('TSModuleToggle', function(args)
  local module = args.fargs[1]
  local state = args.fargs[2]
  ts_modules_callback(module, state, args.bang)
end, {
  desc = '[TSModules] Toggle module',
  bang = true,
  bar = true,
  complete = function(current, cmd, cur_pos)
    vim.print({ current, cmd, cur_pos })

    local cmd_parts = vim.split(cmd, ' ')

    if #cmd_parts >= 4 then
      return
    end

    if #cmd_parts == 3 then
      return get_matched({ 'enable', 'disable' }, current)
    end

    return ts_modules_complete_name(current)
  end,
  nargs = '+',
})

vim.api.nvim_create_user_command('TSModuleEnable', function(args)
  local module = args.fargs[1]
  if module ~= nil then
    return ts_modules_callback(module, 'enable', args.bang)
  end

  local names = ts_modules_get_names()
  require('utils.fzf').fzf({
    name = 'ts_modules',
    source = names,
    fullscreen = args.bang,
    fzf_opts = { '--no-multi', '--prompt', 'TSModule enable> ' },
    sink = function(options)
      if #options < 2 then
        return
      end
      local selected = options[2]
      return ts_modules_callback(selected, 'enable')
    end,
  })
end, {
  desc = '[TSModules] Enable module',
  bang = true,
  bar = true,
  complete = ts_modules_complete_fn,
  nargs = '?',
})

vim.api.nvim_create_user_command('TSModuleDisable', function(args)
  local module = args.fargs[1]
  if module ~= nil then
    return ts_modules_callback(module, 'disable', args.bang)
  end

  local names = ts_modules_get_names()
  require('utils.fzf').fzf({
    name = 'ts_modules',
    source = names,
    fullscreen = args.bang,
    fzf_opts = { '--no-multi', '--prompt', 'TSModule disable> ' },
    sink = function(options)
      if #options < 2 then
        return
      end
      local selected = options[2]
      return ts_modules_callback(selected, 'disable')
    end,
  })
end, {
  desc = '[TSModules] Disable module',
  bang = true,
  bar = true,
  complete = ts_modules_complete_fn,
  nargs = '?',
})

vim.api.nvim_create_user_command('TSModuleOn', function(args)
  local module = args.fargs[1]
  ts_modules_switch(module, 'on')
end, {
  desc = '[TSModules] Activate module',
  bang = true,
  bar = true,
  complete = ts_modules_complete_fn,
  nargs = 1,
})

vim.api.nvim_create_user_command('TSModuleOff', function(args)
  local module = args.fargs[1]
  ts_modules_switch(module, 'off')
end, {
  desc = '[TSModules] Activate module',
  bang = true,
  bar = true,
  complete = ts_modules_complete_fn,
  nargs = 1,
})

vim.api.nvim_create_user_command('Bcd', function(args)
  local buf = type(args.fargs[1]) == 'number' and tonumber(args.fargs[1]) or 0
  require('utils.funcs').buffer_cd(buf)
end, {
  bar = true,
  bang = true,
  nargs = '?',
})
