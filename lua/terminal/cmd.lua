-- Get this script file path
local __file = vim.fn.substitute(debug.getinfo(1, "S").source:match("@(.*)$"), '\\', '/', 'g')

local short_path = function(path)
  local shorted = vim.fn.system('for %A in ("' .. path .. '") do @echo %~sA')
  local cleaned = shorted:gsub('\n', '')
  return vim.fn.substitute(cleaned, '\\', '/', 'g')
end

local find_gitbash = function()
  local candidates = vim.fn.systemlist({ 'where.exe', 'bash' })
  local found = vim.tbl_filter(function(value)
    local _, matches = value:gsub('[Gg]it', '')
    return matches > 0
  end, candidates)[1]

  if found == nil then
    return
  end

  return short_path(found)
end

---@param query string Query for initial search
---@param fullscreen boolean Whether or not to display in fullscreen
local fzf_buffers = function(query, fullscreen)
  local remove_list = vim.fn.substitute(vim.fn.tempname(), '\\', '/', 'g')

  local repo_root = vim.fn.fnamemodify(vim.fs.find('.git', { upward = true, path = __file })[1], ':h')
  local remove_command = ''

  if vim.fn.has('win32') == 1 then
    local gitbash = find_gitbash()

    if gitbash == nil then
      vim.notify('Cannot find gitbash', vim.log.levels.ERROR)
      return
    end

    local drive_letter = repo_root:sub(1, 1):lower()
    local gitbash_repo = '/' .. drive_letter .. repo_root:gsub('^[A-Za-z]:', '')
    remove_command = gitbash .. ' ' .. gitbash_repo .. '/bin/remove_buff.sh'
  else
    local bin_path = repo_root .. '/bin'
    remove_command = bin_path .. '/remove_buff.sh'
  end

  remove_command = remove_command .. ' {3} "' .. remove_list .. '"'

  local spec = vim.fn['fzf#vim#with_preview']({
    placeholder = '{1}',
    options = {
      '--cycle',
      '--no-multi', '--ansi',
      '--input-border=rounded',
      '--bind', 'ctrl-l:change-preview-window(down|hidden|)',
      '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
      '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
      '--bind', 'shift-up:preview-up,shift-down:preview-down',
      '--bind', 'ctrl-^:toggle-preview,ctrl-s:toggle-sort',
      '--bind', 'alt-c:clear-query,alt-f:first,alt-l:last,alt-a:select-all,alt-d:deselect-all',
      '--bind', 'ctrl-q:execute-silent(' .. remove_command .. ')+exclude+bell',
    },
    exit = function()
      ---@diagnostic disable-next-line
      if not (vim.uv or vim.loop).fs_stat(remove_list) then
        return
      end

      local buffers = vim.fn.readfile(remove_list) --[[@as string[] ]]
      if #buffers == 0 then
        return
      end

      -- pcall(vim.fn.delete, remove_list)

      for _, buffer in ipairs(buffers) do
        local bufnr = tonumber(buffer)
        if vim.fn.bufloaded(bufnr) then
          vim.cmd('bd! ' .. buffer)
        end
      end
    end
  })

  vim.fn['fzf#vim#buffers'](query or '', spec, fullscreen and 1 or 0)
end

local register = function()
  vim.api.nvim_create_user_command('Buffers', function(opts)
      fzf_buffers(opts.fargs[1], opts.bang)
    end,
    {
      desc = '[fzf] Buffers with the ability to close selected buffers with ctrl+q',
      bang = true,
      complete = 'buffer',
      bar = true,
      nargs =
      '?'
    })
end

return {
  find_gitbash = find_gitbash,
  short_path = short_path,
  fzf_buffers = fzf_buffers,
  register = register,
}
