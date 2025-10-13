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

return {
  helptags = helptags,
}
