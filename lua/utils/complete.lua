---Configure lsp completion
---@param client vim.lsp.Client Client id
---@param buffer integer Butter to attach completion to
---@param opts? { triggerCharacters?: string[]; } Options to configure completion
local configure = function(client, buffer, opts)
  if not client:supports_method('textDocument/completion') then
    return
  end

  opts = opts or {}

  ---[[Code required to activate autocompletion and trigger it on each keypress

  if opts.triggerCharacters then
    client.server_capabilities.completionProvider.triggerCharacters = opts.triggerCharacters
  else
    client.server_capabilities.completionProvider.triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz.', '')
  end

  -- NOTE: The below autocommand makes completion to start more often
  -- but it become very spamy
  -- vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
  --   buffer = buffer,
  --   callback = function()
  --     vim.lsp.completion.get()
  --   end
  -- })
  ---]]

  ---[[ Code that starts the completion
  vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
  ---]]

  ---[[ Manual trigger
  vim.keymap.set({ 'i', 's' }, '<c-b>', function()
    vim.lsp.completion.get()
  end, { buffer = buffer, silent = true, noremap = true, desc = '[completion] start completing' })
  ---]]

  ---[[ Map to allow add new line while complete visible
  vim.keymap.set({ 'i', 's' }, '<nl>', function()
    if vim.fn.pumvisible() == 1 then
      return '<c-e><nl>'
    else
      return '<nl>'
    end
  end, { desc = '[completion] move to next line', expr = true, silent = true, buffer = buffer })
  ---]]

  ---[[ Code that adds jumps between placeholders in snippets
  vim.keymap.set({ 'i', 's' }, '<tab>', function()
    if vim.snippet.active({ direction = 1 }) then
      return '<cmd>lua vim.snippet.jump(1)<cr>'
    else
      return '<tab>'
    end
  end, { desc = '[snippet] Next placeholder', expr = true, silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<c-l>', function()
    if vim.snippet.active({ direction = 1 }) then
      vim.snippet.jump(1)
    end
  end, { desc = '[snippet] Next placeholder', silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<s-tab>', function()
    if vim.snippet.active({ direction = -1 }) then
      return '<cmd>lua vim.snippet.jump(-1)<cr>'
    else
      return '<s-tab>'
    end
  end, { desc = '[snippet] Prev placeholder', expr = true, silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<c-h>', function()
    if vim.snippet.active({ direction = -1 }) then
      vim.snippet.jump(-1)
    end
  end, { desc = '[snippet] Prev placeholder', silent = true })
  ---]]

  ---[[Code required to add documentation popup for an item
  local _, cancel_prev = nil, function() end
  vim.api.nvim_create_autocmd('CompleteChanged', {
    buffer = buffer,
    callback = function()
      cancel_prev()
      local info = vim.fn.complete_info({ 'selected' })
      local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
      if nil == completionItem then
        return
      end
      _, cancel_prev = vim.lsp.buf_request(
        buffer,
        vim.lsp.protocol.Methods.completionItem_resolve,
        completionItem,
        function(err, item, ctx)
          if not item then
            return
          end
          local docs = (item.documentation or {}).value
          local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
          if win.winid and vim.api.nvim_win_is_valid(win.winid) then
            vim.treesitter.start(win.bufnr, 'markdown')
            vim.wo[win.winid].conceallevel = 3
          end
        end
      )
    end,
  })
  ---]]
end

return {
  configure = configure,
}
