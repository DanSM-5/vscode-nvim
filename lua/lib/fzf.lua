---@class fzf.options
---@field source (fun(): table) | table
---@field sink fun(options: string[]): nil
---@field fzf_opts? string[]
---@field name? string
---@field fullscreen? boolean

---Wraper command for fzf#run(fzf#wrap({}))
---@param opts fzf.options
---@return nil
local fzf = function (opts)
  if not vim.g.loaded_fzf then
    vim.notify('Fzf plugin is not laoded!', vim.log.levels.WARN)
    return
  end

  -- Default history file
  local name = opts.name or 'fzf-history-default'
  local fullscreen = opts.fullscreen and 1 or 0
  local source = opts.source
  local options = opts.fzf_opts or {}
  local sink = opts.sink or function (tbl)
    for _, value in ipairs(tbl) do
      vim.notify(value)
    end
  end

  local fzf_opts_wrap = vim.fn['fzf#wrap'](name, { source = source, options = options }, fullscreen)
  fzf_opts_wrap['sink*'] = sink -- 'sink*' needs to be assigned outside wrap()
  vim.fn['fzf#run'](fzf_opts_wrap)
end

---Helper function for helptags
---@param fullscreen boolean
local helptags = function(fullscreen)
  local full = fullscreen and 1 or 0
  local fzf_preview_options = vim.g.fzf_preview_options

  if vim.fn.has('win32') ~= 1 then
    local script_preview = vim.g.scripts_dir .. '/tabpreview.sh'
    local helptags_spec = vim.fn['fzf#vim#with_preview']({ placeholder = '--tag {2}:{3}:{4}' })
    vim.list_extend(fzf_preview_options, {
      '--no-multi',
      '--preview',
      string.format('/usr/bin/bash "%s" {2}:{3}:{4}', script_preview),
    })
    helptags_spec.options = vim.list_extend(helptags_spec.options, fzf_preview_options)

    vim.fn['fzf#vim#helptags'](helptags_spec, full)
    return
  end

  -- NOTE: The preview won't work correctly using windows powershell
  -- It is related to extracting the line number from the help file
  -- using vim/nvim. On windows powershell the command never returns.
  -- Leaveing here as fallback but won't work.
  local pwsh = vim.fn.executable('pwsh') and 'pwsh' or 'powershell'

  vim.list_extend(fzf_preview_options, {
    '--no-multi',
    '--with-shell',
    string.format('%s -NoLogo -NonInteractive -NoProfile -Command', pwsh),
    '--preview', string.format('%s/tagpreview.ps1 {+f}', vim.g.scripts_dir)
  })

  local helptags_spec = {
    options = fzf_preview_options,
    placeholder = '--tag {2}:{3}:{4}',
  }

  vim.fn['fzf#vim#helptags'](helptags_spec, full)
end

---@class fzf.rg.args
---@field query? string
---@field fullscreen? boolean
---@field prompt? string
---@field options? string[]
---@field template? string
---@field directory? string

---show fzf rg
---@param opts fzf.rg.args
local function fzf_rg(opts)
  -- Ensure opts is defined with defaults
  ---@type fzf.rg.args
  opts = vim.tbl_deep_extend('force', {
    fullscreen = false,
    prompt = 'RG> ',
    options = {},
    template = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true',
    query = '',
    -- prevent a require if not needed
    directory = opts.directory or require('utils.funcs').git_path()
  }, opts)

  -- Spec creation
  local spec = {
    options = {
      '--ansi',
      '--prompt', opts.prompt,
      '--layout=reverse',
    },
  }
  vim.list_extend(spec.options, vim.g.fzf_bind_options) -- inject globals
  vim.list_extend(spec.options, opts.fullscreen and {
    '--preview-window', 'up,60%,wrap',
  } or { '--preview-window', 'right,60%,wrap' }) -- inject mode

  -- Query parsing
  ---@type string
  local query = opts.query
  local esc_query = vim.fn.has('win32') == 1 and vim.fn.shellescape(query) or vim.fn['fzf#shellescape'](query)
  local start_reload = string.format(opts.template, esc_query)
  local change_reload = string.format(opts.template, '{q}')
  vim.list_extend(spec.options, {
    '--bind', string.format('start:reload:%s', start_reload),
    '--bind', string.format('change:reload:%s', change_reload),
  })

  -- Preview
  if vim.fn.has('win32') then
    vim.list_extend(spec.options, {
      '--with-shell', string.format(
        '%s -NoLogo -NonInteractive -NoProfile -Command',
        vim.fn.executable('pwsh') and 'pwsh' or 'powershell'
      ),
      '--preview', string.format('%s/preview.ps1 {}', vim.g.scripts_dir)
    })
  else
    vim.list_extend(spec.options, {
      '--preview', string.format('%s/preview.sh {}', vim.g.scripts_dir)
    })
  end

  -- Options override
  vim.list_extend(spec.options, opts.options)

  -- force run on directory
  local cwd = vim.fn.getcwd()
  vim.cmd.cd(opts.directory)
  pcall(vim.fn['fzf#vim#grep2'], 'rg', query, spec, opts.fullscreen and 1 or 0)
  vim.cmd.cd(cwd)
end

local todo_keywords = {
  'TODO',
  'BUG',
  'WARNING',
  'TEST',
  'TESTING',
  'PASSED',
  'FAILED',
  'INFO',
  'WARN',
  'OPTIM',
  'NOTE',
  'OPTIMIZE',
  'XXX',
  'HACK',
  'FIX',
  'FIXME',
  'FIXIT',
  'ISSUE',
  'PERFORMANCE',
  'PERF',
}

---@param keywords string[]
---@param fullscreen boolean
local todos = function (keywords, fullscreen)
  local query = #keywords > 0 and keywords or todo_keywords
  ---@diagnostic disable-next-line: cast-local-type
  query = string.format('\\b(%s):', table.concat(query, '|'))

  ---@type fzf.rg.args
  local opts = {
    query = query,
    fullscreen = fullscreen,
    prompt = 'TODOs> ',
  }

  fzf_rg(opts)
end

---Complete function for todos
---@param current string
---@param cmd? string
---@param position? integer
---@return string[]
local function todos_complete(current, cmd, position)
  local options = todo_keywords
  local matched = vim.tbl_filter(function(option)
    local _, matches = string.gsub(option, '^' .. current:upper(), '')
    return matches > 0
  end, options)

  return #matched > 0 and matched or options
end

return {
  fzf = fzf,
  fzf_rg = fzf_rg,
  helptags = helptags,
  todos = todos,
  todos_complete = todos_complete,
  todo_keywords = todo_keywords,
}
