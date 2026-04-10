
---Open fshow script in a floating terminal window
---@param dir? string
---@param opts? terminal.jobstart.opts
local function fshow(dir, opts)
  opts = opts or {}
  -- TODO: Consider make the fshow script a standalone script in path "user-scripts"
  -- rather than a utility script.
  local cwd = dir or require('lib.fs').git_path()
  local script_preview = vim.fn.stdpath('config') .. '/bin/git-preview'
  ---@type string[]
  local script_cmd = {}

  if vim.fn.has('win32') == 1 then
    script_cmd = {
      '-NoLogo',
      '-NonInteractive', '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', script_preview .. '.ps1',
    }
    if vim.fn.executable('pwsh') then
      table.insert(script_cmd, 1, 'pwsh.exe')
    else
      table.insert(script_cmd, 1, 'powershell.exe')
    end
  else
    script_cmd = { script_preview .. '.sh' }
  end

  opts.cwd = cwd

  -- require('lazy.util').float_term(script_cmd, { cwd = cwd })
  require('lib.terminal').float_term({
    cmd = script_cmd,
    term = opts,
  })
end

---Open git log in a floating terminal buffer
---@param dir? string
local function git_log(dir)
  local cwd = dir or require('lib.fs').git_path()

  -- require('lazy.util').float_term({
  --   'git', 'log', '--oneline', '--decorate', '--graph',
  -- }, { cwd = cwd })

  require('lib.terminal').float_term({
    cmd = {
    'git', 'log', '--oneline', '--decorate', '--graph',
    },
    term = { cwd = cwd },
  })
end

return {
  fshow = fshow,
  git_log = git_log,
}

