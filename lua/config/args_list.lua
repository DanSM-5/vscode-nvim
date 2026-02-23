-- Ref: https://www.reddit.com/r/neovim/comments/1oikemy/harpoongrapple_for_arglist/
-- Ref: https://www.reddit.com/r/neovim/comments/1og2pg9/mom_can_i_have_harpoon_we_have_harpoon_at_home/
-- Ref: https://pastebin.com/c2XygzHx
-- Ref: https://github.com/BirdeeHub/birdeevim/blob/d4c90f72ba80fb17c89081cba2932c7da67448ee/pack/personalplugins/start/argmark/lua/argmark.lua
-- Ref: https://github.com/BirdeeHub/argmark

local function set_keymaps()
  vim.keymap.set('n', '<leader>aa', function()
    local count = vim.v.count

    if count == 0 then
      vim.cmd.argadd('%') -- Add to arglist
    else
      vim.cmd((count - 1) .. 'argadd')
    end

    vim.cmd.argdedupe() -- prevent duplicates
    -- vim.cmd.args() -- Show current list
    vim.print(('ArgList: %d item(s)'):format(#vim.fn.argv()))
  end, {
    desc = '[ArgList] Add buffer to arglist',
    noremap = true,
  })
  vim.keymap.set('n', '<leader>ad', function()
    local count = vim.v.count

    if count == 0 then
      vim.cmd.argdelete('%') -- Delete from arglist
    else
      vim.cmd(count .. 'argdelete')
    end

    vim.cmd.argdedupe() -- prevent duplicates
    -- vim.cmd.args() -- Show current list
    vim.print(('ArgList: %d item(s)'):format(#vim.fn.argv()))
  end, {
    desc = '[ArgList] Delete buffer from arglist',
    noremap = true,
  })

  -- assign arg to each number
  for i = 1, 9 do
    vim.keymap.set(
      'n',
      '<leader>' .. i,
      '<CMD>argument ' .. i .. '<CR>',
      { silent = true, desc = '[ArgList] Go to arg ' .. i }
    )
    -- vim.keymap.set(
    --   'n',
    --   '<leader>h' .. i,
    --   '<CMD>' .. i - 1 .. 'argadd<CR>',
    --   { silent = true, desc = '[ArgList] Add current to arg ' .. i }
    -- )
    -- vim.keymap.set(
    --   'n',
    --   '<leader>D' .. i,
    --   '<CMD>' .. i .. 'argdelete<CR>',
    --   { silent = true, desc = '[ArgList] Delete arg ' .. i }
    -- )
  end
end

return {
  set_keymaps = set_keymaps,
}
