
---Open fshow script in a floating terminal window
---@param dir? string
local function fshow(dir)
  -- TODO: Consider make the fshow script a standalone script in path "user-scripts"
  -- rather than a utility script.
  local cwd = dir or require('utils.funcs').git_path()
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

  require('lazy.util').float_term(script_cmd, { cwd = cwd })
end

---Open git log in a floating terminal buffer
---@param dir? string
local function git_log(dir)
  local cwd = dir or require('utils.funcs').git_path()

  require('lazy.util').float_term({
    'git', 'log', '--oneline', '--decorate', '--graph',
  }, { cwd = cwd })
end

return {
  fshow = fshow,
  git_log = git_log,
}

