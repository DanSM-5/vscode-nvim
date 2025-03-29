
-- -- Mapping to remove marks on the line uner the cursor
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
  --                                          [bufnum, lnum, col, off]
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

local git_path = function ()
  -- " Directory holding the current file
  local file_dir = vim.fn.trim(vim.fn.expand('%:p:h'))

  local gitcmd = 'cd '..vim.fn.shellescape(file_dir)..' && git rev-parse --show-toplevel'
  local gitpath = vim.fn.trim(vim.fn.system(gitcmd))

  if vim.fn.isdirectory(gitpath) == 1 then
    return gitpath
  end

  local buffpath = vim.fn.substitute(vim.fn.trim(vim.fn.expand('%:p:h')), '\\', '/', 'g')

  if vim.fn.isdirectory(buffpath) == 1 then
    return buffpath
  end
end

local buffer_cd = function()
  local buffer_path = git_path()
  if buffer_path ~= nil and vim.fn.empty(buffer_path) ~= 1 then
    vim.cmd('cd '..buffer_path)
    vim.notify('Changed to: ' .. buffer_path, vim.log.levels.INFO)
  else
    vim.notify('Unable to cd into: ' .. buffer_path, vim.log.levels.WARN)
  end
end

return {
  delete_marks_curr_line = delete_marks_curr_line,
  regmove = regmove,
  git_path = git_path,
  buffer_cd = buffer_cd,
}
