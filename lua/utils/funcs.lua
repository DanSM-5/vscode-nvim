-- General utility functions without an specific category


-- Mapping to remove marks on the line under the cursor
local delete_marks_curr_line = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_line = vim.fn.line('.')
  --                            [bufnum, lnum, col, off]
  ---@type { mark: string; pos: [number, number, number, number] }[]
  local all_marks_local = vim.fn.getmarklist(bufnr)
  for _, mark in ipairs(all_marks_local) do
    if mark.pos[2] == cur_line and string.match(mark.mark, "'[a-z]") then
      vim.notify('Deleting mark: ' .. string.sub(mark.mark, 2, 2))
      vim.api.nvim_buf_del_mark(bufnr, string.sub(mark.mark, 2, 2))
    end
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  ---@type { file: string; mark: string; pos: [number, number, number, number] }[]
  local all_marks_global = vim.fn.getmarklist()
  for _, mark in ipairs(all_marks_global) do
    -- local expanded_file_name = vim.api.nvim_buf_get_name(mark.pos[1])
    local expanded_file_name = vim.fn.fnamemodify(mark.file, ':p')
    if bufname == expanded_file_name and mark.pos[2] == cur_line and string.match(mark.mark, "'[A-Z]") then
      vim.notify('Deleting mark: ' .. string.sub(mark.mark, 2, 2))
      vim.api.nvim_del_mark(string.sub(mark.mark, 2, 2))
    end
  end
end

---Copy the content from a register to another
---@param destination string Name of register to copy to
---@param source string Name of register to copy from
local function regmove(destination, source)
  vim.fn.setreg(destination, vim.fn.getreg(source))
end

---Cd to the repository containing buf
---or to the directory containing buf
---@param buf integer? buffer to reference when attempt cd into
local buffer_cd = function(buf)
  local buffer = buf or 0

  ---@type string|nil
  local buffer_path = require('lib.fs').get_file(buffer)
  -- TEST: removing expansion to parent (':h') because `git_path()`
  -- expects the path to a file and not the path to a directory.
  -- if buffer_path ~= nil then
  --   buffer_path = vim.fn.fnamemodify(buffer_path, ':h')
  -- elseif buf ~= 0 and buf ~= nil then
  if buf ~= 0 and buf ~= nil then
    -- A buffer other than current was provided but we are unable to locate
    -- the path to that buffer. Return here as below will infer current buffer
    -- if nil or 0 is passed
    vim.notify(('[Bcd] cannot find path for buf "%d"'):format(buffer), vim.log.levels.WARN)
    return
  end
  buffer_path = require('lib.fs').git_path(buffer_path)

  if buffer_path ~= nil then
    vim.cmd.cd(buffer_path)
    vim.notify(string.format('Changed to (%d): %s', buffer, buffer_path), vim.log.levels.INFO)
    return
  end

  vim.notify(('Unable to cd into buffer "%d"'):format(buffer), vim.log.levels.WARN)
end

return {
  delete_marks_curr_line = delete_marks_curr_line,
  regmove = regmove,
  buffer_cd = buffer_cd,
}
