local buf = vim.api.nvim_get_current_buf()

---@class netrw.createFile
---@field edit? boolean Whether the file should be open immediately to edit
---@field name? string Name of the file
---@field keep_netwr? boolean Whether to keep netrw opened

---Prompts and creates a file in netrw display root
---@param opts netrw.createFile Options for function
local function createFile(opts)
  opts = opts or {}

  ---Inner function that creates a file
  ---@param input string
  local function _createFile (input)
    -- local from_win = vim.g.custom_netrw_from_win
    -- if not input or not from_win or not vim.api.nvim_win_is_valid(from_win) then
    --   return
    -- end

    if not input then
      return
    end

    local dir = vim.fs.normalize(vim.fn.expand('%'):gsub('NetrwTreeListing', ''), {})

    if vim.fn.isdirectory(dir) == 0 then
      return
    end

    local new_file = vim.fs.joinpath(dir, input)



    -- NOTE: Edit does not override the file clean,
    -- so safe to edit even if it exists
    if opts.edit then

      local from_win = vim.g.custom_netrw_from_win
      if opts.keep_netwr and from_win and vim.api.nvim_win_is_valid(from_win) then
        -- Go back to previous window
        vim.api.nvim_set_current_win(from_win)
      else
        -- Close netrw and return to previous window
        vim.cmd.Lex({ bang = true })
      end

      vim.cmd.edit(new_file)
      return
    end

    if vim.uv.fs_stat(new_file) then
      vim.notify('File already exists', vim.log.levels.ERROR)
      return
    end

    -- Creates the file with no content
    vim.fn.writefile({}, new_file)
    -- Refresh netrw buffer
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-l>', true, true, true), 'n', false)
  end

  if opts.name then
    _createFile(opts.name)
    return
  else
    vim.ui.input({ prompt = 'Enter filename: ' }, _createFile)
  end
end

vim.keymap.set('n', '%', createFile, { buffer = buf, noremap = true, desc = '[netrw] create file' })
