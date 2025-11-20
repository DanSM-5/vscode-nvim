local buf = vim.api.nvim_get_current_buf()

---Prompts and creates a file in netrw display root
---@param opts { edit: boolean; }
local function createFile(opts)
  opts = opts or {}

  vim.ui.input({ prompt = 'Enter filename: ' }, function(input)
    local from_win = vim.g.custom_netrw_from_win
    if not input or not from_win or not vim.api.nvim_win_is_valid(from_win) then
      return
    end

    local dir = vim.fs.normalize(vim.fn.expand('%'):gsub('NetrwTreeListing', ''), {})

    if vim.fn.isdirectory(dir) == 0 then
      return
    end

    local new_file = vim.fs.joinpath(dir, input)

    if vim.uv.fs_stat(new_file) then
      vim.notify('File already exists', vim.log.levels.ERROR)
      return
    end


    if opts.edit then
      vim.cmd.Lex({ bang = true })
      vim.cmd.edit(new_file)
    else
      vim.fn.writefile({}, new_file)
    end
  end)
end

vim.keymap.set('n', '%', createFile, { buffer = buf, noremap = true, desc = '[netrw] create file' })
