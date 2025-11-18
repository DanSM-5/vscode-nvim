---@class snap.opts
---@field line1 integer First line in range
---@field line2 integer Second line in range
---@field full? boolean Whether to apply to the whole buffer
---@field file? string filename to take the snap from
---@field output? string directory or filename where to output the snap

---Get a snap from the code
---@param opts snap.opts options for the snap
local function snap(opts)
  if vim.fn.executable('codesnap') == 0 then
    vim.notify('[Snap] not executable "codesnap" found', vim.log.levels.ERROR)
    return
  end

  opts = opts or {}
  local file = opts.file or '%'

  if file == '%' then
    -- expand is different from empty string if buffer has a name
    if vim.fn.expand('%:p') ~= '' then
      file = require('lib.fs').get_file(0)
    end
  else
    file = require('lib.fs').expand_path(file)
  end

  -- NOOP if got a directory
  if vim.fn.isdirectory(file) == 1 then
    return
  end

  local output = (opts.output and type(opts.output) == 'string' and vim.fn.isdirectory(opts.output)) and opts.output
    or 'clipboard'
  local line1 = opts.line1
  local line2 = opts.line2
  local handle_wsl_img = false

  if vim.fn.has('wsl') == 1 and output == 'clipboard' then
    output = vim.fn.tempname() .. '.png'
    handle_wsl_img = true
  end

  local command = {
    'codesnap',
    '--output',
    output,
    '--has-line-number',
  }

  local on_complete = vim.schedule_wrap(function()
    if handle_wsl_img then
      local img = vim.system({ 'wslpath', '-w', output }, { text = true }):wait().stdout

      vim.system({
        'powershell.exe',
        '-windowstyle',
        'hidden',
        '-Command',
        ("Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.Clipboard]::SetImage($([System.Drawing.Image]::FromFile('%s')))"):format(img),
      }, {}, vim.schedule_wrap(function()
        vim.notify('[Snap] Snap completed', vim.log.levels.INFO)
      end))
      return
    end

    vim.notify('[Snap] Snap completed', vim.log.levels.INFO)
  end)

  -- Buffer is a file
  if vim.uv.fs_stat(file) then
    vim.list_extend(command, {
      '--from-file', file,
    })

    if not opts.full then
      vim.list_extend(command, {
        '--range', string.format('%d:%d', line1, line2),
      })
    end

    vim.system(command, {}, on_complete)
    return
  end

  -- Buffer is not a file

  -- range is used for getting the code from the buffer
  -- Should use `vim.api.nvim_buf_get_lines`?
  local lines = opts.full and vim.fn.getline(1, '$') or vim.fn.getline(line1, line2)
  lines = type(lines) == 'string' and { lines } or lines
  ---@cast lines string[]
  local code = table.concat(lines, '\n')


  vim.list_extend(command, {
    '--from-code', code,
  })

  vim.system(command, {}, on_complete)
end

return {
  snap = snap,
}
