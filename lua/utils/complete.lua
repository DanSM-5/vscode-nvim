--- Module to handle auto completion of lsp servers
--- This helper also allows to add multiple lsp clients to a
--- single buffer and prioritize which resolves the documentation

---@class complete.client.data
---@field client_id integer
---@field name string
---@field priority integer

---@type table<integer, { insertCharPre: integer; completeChanged: integer } | nil>
local complete_autocmds = {}

local complete_group = vim.api.nvim_create_augroup('complete_group', { clear = true })
vim.api.nvim_create_autocmd('LspDetach', {
  group = complete_group,
  desc = '[complete] unregister clients from buffers',
  callback = function(info)
    local buf = info.buf
    if not complete_autocmds[buf] then
      return
    end

    local detach_client_id = info.data.client_id --[[@as integer]]
    local clients = vim.lsp.get_clients({ method = vim.lsp.protocol.Methods.textDocument_completion, bufnr = buf })
    clients = vim.iter(clients):filter(function(c)
      ---@cast c vim.lsp.Client
      return c.id ~= detach_client_id
    end)

    -- Cleanup autocmds on buffer if no more lsp clients attached
    if #clients == 0 and complete_autocmds[buf] then
      pcall(vim.api.nvim_del_autocmd, complete_autocmds[buf].completeChanged)
      pcall(vim.api.nvim_del_autocmd, complete_autocmds[buf].insertCharPre)
      complete_autocmds[buf] = nil
    end
  end,
})

local function style_docs_win()
  -- Needs 'selected' to return preview_winid
  local info = vim.fn.complete_info({ 'selected', 'preview_winid' })
  local winId = vim.tbl_get(info, 'preview_winid') --[[@as integer|nil]]
  if winId and vim.api.nvim_win_is_valid(winId) then
    vim.api.nvim_win_set_config(winId, { border = 'rounded' })
    vim.wo[winId].conceallevel = 3
  end
end

---Configure lsp completion
---@param client vim.lsp.Client Client id
---@param buffer integer Butter to attach completion to
---@param opts? { triggerCharacters?: false | string[]; } Options to configure completion
local configure = function(client, buffer, opts)
  if not client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
    return
  end

  opts = opts or {}

  ---[[Code required to activate autocompletion and trigger it on each keypress

  if opts.triggerCharacters == false then
    -- Should not be updated
  elseif opts.triggerCharacters then
    -- Use provided
    client.server_capabilities.completionProvider.triggerCharacters = opts.triggerCharacters
  else
    -- Use default
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
    if vim.fn.pumvisible() == 1 then
      return '<c-n>' -- go to next option
    elseif vim.snippet.active({ direction = 1 }) then
      return '<cmd>lua vim.snippet.jump(1)<cr>' -- move to next placeholder
    else
      return '<tab>' -- default tab
    end
  end, { desc = '[snippet] Next placeholder', expr = true, silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<c-l>', function()
    if vim.snippet.active({ direction = 1 }) then
      vim.snippet.jump(1)
    end
  end, { desc = '[snippet] Next placeholder', silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<s-tab>', function()
    if vim.fn.pumvisible() == 1 then
      return '<c-p>' -- go to previous option
    elseif vim.snippet.active({ direction = -1 }) then
      return '<cmd>lua vim.snippet.jump(-1)<cr>' -- move to previous placeholder
    else
      return '<s-tab>' -- default s-tab
    end
  end, { desc = '[snippet] Prev placeholder', expr = true, silent = true, buffer = buffer })

  vim.keymap.set({ 'i', 's' }, '<c-h>', function()
    if vim.snippet.active({ direction = -1 }) then
      vim.snippet.jump(-1)
    end
  end, { desc = '[snippet] Prev placeholder', silent = true })
  ---]]

  ---[[Code required to add documentation popup for an item

  if complete_autocmds[buffer] then
    pcall(vim.api.nvim_del_autocmd, complete_autocmds[buffer].completeChanged)
    pcall(vim.api.nvim_del_autocmd, complete_autocmds[buffer].insertCharPre)
  else
    complete_autocmds[buffer] = {}
  end

  -- Define autocmds
  complete_autocmds[buffer].completeChanged = vim.api.nvim_create_autocmd('CompleteChanged', {
    buffer = buffer,
    desc = '[Complete] Set options on completion',
    callback = function()
      -- local info = vim.fn.complete_info({ 'preview_winid' })
      -- vim.print(info)
      style_docs_win()
    end,
  })
  complete_autocmds[buffer].insertCharPre = vim.api.nvim_create_autocmd('InsertCharPre', {
    buffer = buffer,
    desc = '[Complete] Set options on completion',
    callback = function()
      style_docs_win()
    end,
  })

  -- complete_autocmds[buffer].completeChanged = vim.api.nvim_create_autocmd('CompleteChanged', {
  --   buffer = buffer,
  --   callback = function()
  --     -- _cancel_prev()
  --     -- local info = vim.fn.complete_info({ 'selected' }) ---@type { selected: integer }
  --     -- -- vim.print(vim.v.completed_item)
  --     -- local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
  --     -- local client_id = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'client_id')
  --
  --     -- completionItem:
  --     -- {
  --     --   abbr = "nvim_set_current_win",
  --     --   info = "",
  --     --   kind = "Text",
  --     --   menu = "",
  --     --   user_data = {
  --     --     nvim = {
  --     --       lsp = {
  --     --         client_id = 6,
  --     --         completion_item = {
  --     --           data = {
  --     --             label = "nvim_set_current_win"
  --     --           },
  --     --           kind = 1,
  --     --           label = "nvim_set_current_win"
  --     --         }
  --     --       }
  --     --     }
  --     --   },
  --     --   word = "nvim_set_current_win"
  --     -- }
  --
  --     -- if nil == completionItem or not client_id then
  --     --   return
  --     -- end
  --
  --     --- SAMPLE WITH vim.lps.buf_request_all ---
  --
  --     -- _cancel_prev = vim.lsp.buf_request_all(
  --     --   buffer,
  --     --   vim.lsp.protocol.Methods.completionItem_resolve,
  --     --   completionItem,
  --     --   function(results, ctx, config)
  --     --     ---@cast results table<integer, { err?: lsp.ResponseError; result: lsp.CompletionItem; context: lsp.HandlerContext }>
  --     --     -- local docs = vim.tbl_get(results[client_id] or {}, 'result', 'documentation', 'value')
  --     --     -- if nil == docs then
  --     --     --   return
  --     --     -- end
  --     --
  --     --     local res = vim.tbl_get(results[client_id] or {}, 'result') --[[@as lsp.CompletionItem]]
  --     --     if res and show_docs(res, info) then
  --     --       return
  --     --     end
  --     --   end
  --     -- )
  --
  --     --- SAMPLE WITH client:request ---
  --
  --     -- local req_client = vim.lsp.get_client_by_id(client_id)
  --     -- if not req_client then
  --     --   return
  --     -- end
  --     --
  --     -- local _, reqid = req_client:request(
  --     --   vim.lsp.protocol.Methods.completionItem_resolve,
  --     --   completionItem,
  --     --   function(err, item, ctx)
  --     --     ---@cast item lsp.CompletionItem
  --     --     if not item then
  --     --       return
  --     --     end
  --     --
  --     --     show_docs(item, info)
  --     --   end,
  --     --   buffer
  --     -- )
  --
  --     -- _cancel_prev = function()
  --     --   local c = vim.lsp.get_client_by_id(client_id)
  --     --   if not c or not reqid then
  --     --     return
  --     --   end
  --     --   pcall(function()
  --     --     c:cancel_request(reqid)
  --     --   end)
  --     -- end
  --
  --     --- SAMPLE WITH sample of textDocument_completion ---
  --
  --     -- client:request(
  --     --   vim.lsp.protocol.Methods.textDocument_completion,
  --     --   completionItem,
  --     --   function(err, item, ctx)
  --     --     if not item then
  --     --       return
  --     --     end
  --
  --     --     local docs = (item.documentation or {}).value
  --     --     local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
  --     --     if win.winid and vim.api.nvim_win_is_valid(win.winid) then
  --     --       vim.api.nvim_win_set_config(win.winid, { border = 'rounded' })
  --     --       vim.treesitter.start(win.bufnr, 'markdown')
  --     --       vim.wo[win.winid].conceallevel = 3
  --     --     end
  --     --   end
  --     -- )
  --
  --     --- SAMPLE WITH buf_request_sync ---
  --
  --     -- local resolvedItem = vim.lsp.buf_request_sync(
  --     --   buffer,
  --     --   vim.lsp.protocol.Methods.completionItem_resolve,
  --     --   completionItem,
  --     --   500
  --     -- ) or {}
  --
  --     -- local docs = vim.tbl_get(resolvedItem[client.id] or {}, 'result', 'documentation', 'value')
  --     -- if nil == docs then
  --     --   return
  --     -- end
  --
  --     -- local winData = vim.api.nvim__complete_set(info['selected'], { info = docs })
  --     -- if not winData.winid or not vim.api.nvim_win_is_valid(winData.winid) then
  --     --   return
  --     -- end
  --
  --     -- vim.api.nvim_win_set_config(winData.winid, { border = 'rounded' })
  --     -- vim.treesitter.start(winData.bufnr, 'markdown')
  --     -- vim.wo[winData.winid].conceallevel = 3
  --
  --     --- SAMPLE WITH buf_request ---
  --
  --     -- _, cancel_prev = vim.lsp.buf_request(
  --     --   buffer,
  --     --   vim.lsp.protocol.Methods.completionItem_resolve,
  --     --   completionItem,
  --     --   function(err, item, ctx)
  --     --     if not item then
  --     --       return
  --     --     end
  --     --     local docs = (item.documentation or {}).value
  --     --     local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
  --     --     if win.winid and vim.api.nvim_win_is_valid(win.winid) then
  --     --       vim.treesitter.start(win.bufnr, 'markdown')
  --     --       vim.wo[win.winid].conceallevel = 3
  --     --       vim.api.nvim_win_set_config(winData.winid, { border = 'rounded' })
  --     --     end
  --     --   end
  --     -- )
  --   end,
  -- })

  ---]]
end

return {
  configure = configure,
  complete_autocmds = complete_autocmds,
}
