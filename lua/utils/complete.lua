local configure = function (client, buffer)
  ---[[Code required to activate autocompletion and trigger it on each keypress
  client.server_capabilities.completionProvider.triggerCharacters = vim.split('qwertyuiopasdfghjklzxcvbnm. ', '')
  vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
    buffer = buffer,
    callback = function()
      vim.lsp.completion.get()
    end
  })
  vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
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
      _, cancel_prev = vim.lsp.buf_request(buffer,
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
        end)
    end
  })
  ---]]
end

return {
  configure = configure,
}
