---@module 'types.lsp_completion'

local utils = {}
local uv = vim.uv or vim.loop
local split_keys = '., '

---Generate id for group name
utils.getId = setmetatable({
  group = {},
}, {
  __call = function(_, group)
    utils.getId.group[group] = utils.getId.group[group] or 0
    utils.getId.group[group] = utils.getId.group[group] + 1
    return utils.getId.group[group]
  end,
})

utils.to_utfindex = function(text, vimindex)
  vimindex = vimindex or #text + 1
  if vim.fn.has('nvim-0.11') == 1 then
    return vim.str_utfindex(text, 'utf-16', math.max(0, math.min(vimindex - 1, #text)))
  end

  -- backwards compatibility
  ---@diagnostic disable-next-line: param-type-mismatch
  return vim.str_utfindex(text, math.max(0, math.min(vimindex - 1, #text)))
end

---Split the string into a list using the separator as delimiter
---@param inputstr string String to split
---@param sep string Character or group of characters to use for separator
---@return string[] List of strings after split
utils.split = function(inputstr, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for str in string.gmatch(inputstr, '([^' .. sep .. ']+)') do
    table.insert(t, str)
  end
  return t
end

---Check if keyword length criteria is met
---@param request AbstractContext
---@param keyword_length integer
---@return boolean
utils.minimum_keyword = function(request, keyword_length)
  local query = string.sub(request.context.cursor_before_line, request.offset)
  return #query >= keyword_length
end

---Create a context data structure expected for cmp completion sources
---@param request LspRpcRequest
---@return AbstractContext
local create_abstracted_context = function(request)
  local line_num = request.position.line
  local col_num = request.position.character
  local buf = vim.uri_to_bufnr(request.textDocument.uri)
  -- local full_line = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
  local full_line = vim.api.nvim_get_current_line()
  local before_char = (request.context and request.context.triggerCharacter) or full_line:sub(col_num, col_num + 1)

  local cursor_before_line = string.sub(full_line, 1, col_num)
  local cursor_after_line = string.sub(full_line, col_num + 1)
  -- local words_before_cursor = vim.split(cursor_before_line, ' ', { plain = true })
  local words_before_cursor = utils.split(cursor_before_line, split_keys)
  local last_word = words_before_cursor[#words_before_cursor]
  local offset = math.max(col_num - #last_word + 1, 0)

  -- NOTE: cmp implementation
  -- local cursor = vim.api.nvim_win_get_cursor(0)
  -- cursor.row = cursor[1]
  -- cursor.col = cursor[2] + 1

  return {
    -- source: https://github.dev/hrsh7th/nvim-cmp/blob/main/lua/cmp/init.lua
    ---@type cmp.Context
    context = {
      -- added
      cache = {},
      id = utils.getId('cmp.context.new'),
      option = { reason = 'none' },
      filetype = vim.api.nvim_get_option_value('filetype', { buf = buf }),
      time = uv.now(),
      cursor_line = full_line,
      cursor_before_line = cursor_before_line,
      cursor_after_line = cursor_after_line,
      aborted = false,

      -- from original cmp2lsp
      cursor = {
        row = line_num,
        col = col_num + 1,
        line = line_num - 1,
        character = utils.to_utfindex(full_line, col_num + 1),
      },
      line = full_line,
      line_before_cursor = full_line:sub(1, col_num),
      bufnr = buf,
      before_char = before_char,
      -- throwaway values to appease some plugins that expect them (neorg)
      prev_context = {
        cursor = {
          row = request.position.line,
          col = col_num + 1,
        },
        line = full_line,
        line_before_cursor = full_line:sub(1, col_num + 1),
        bufnr = buf,
        before_char = before_char,
      },
    },
    -- offset = col_num,
    offset = offset,
    completion_context = {
      triggerKind = 0,
    },
  }
end

local set_insert = function(t, i)
  if not vim.tbl_contains(t, i) then
    table.insert(t, i)
  end
end

local build_trigger_chars = function()
  local chars = {}
  local sources = require('cmp.sources').sources
  for _, source in ipairs(sources) do
    if not source.get_trigger_characters then
      goto continue
    end
    for _, c in ipairs(source:get_trigger_characters()) do
      set_insert(chars, c)
    end
    ::continue::
  end
  return chars
end

local handlers = {
  ['initialize'] = function(_params, callback, _notify_reply_callback)
    local initializeResult = {
      capabilities = {
        renameProvider = {
          prepareProvider = true,
        },
        completionProvider = {
          triggerCharacters = build_trigger_chars(),
          resolveProvider = false,
          completionItem = {
            labelDetailsSupport = true,
          },
        },
      },
      serverInfo = {
        name = 'cmp2lsp',
        version = '0.0.1',
      },
    }

    callback(nil, initializeResult)
  end,

  ---Function handler for `textDocument/completion` method
  ---@param request LspRpcRequest
  ---@param callback fun(err: lsp.ResponseError?, result: any)
  ---@param _ fun(message_id?: integer)
  ['textDocument/completion'] = function(request, callback, _)
    local abstracted_context = create_abstracted_context(request)
    local response = {}
    local sources = require('cmp.sources').sources
    for _, source in ipairs(sources) do
      if type(source) == 'string' then
        if #response > 0 then
          break
        else
          goto continue
        end
      end

      local complete_config = source.cmp2lsp
      local source_is_available = source.is_available ~= nil and source:is_available() or true

      if
        source_is_available
        and (not source.get_trigger_characters or vim.tbl_contains(
          source:get_trigger_characters(),
          abstracted_context.context.before_char
        ))
        and utils.minimum_keyword(abstracted_context, complete_config.keyword_length)
      then
        source:complete(abstracted_context, function(items)
          for _, item in ipairs(items) do
            item.kind = complete_config.kind
            table.insert(response, item)
          end
        end)
      end
      ::continue::
    end

    callback(nil, response)
  end,
}

---@async
---@param co async fun() A fire-and-forget coroutine function
local function fire_and_forget(co)
  coroutine.resume(coroutine.create(co))
end

---@type vim.lsp.Config
return {
  name = 'cmp2lsp',
  on_attach = function(client, bufnr)
    require('utils.lsp_maps').set_lsp_keys(client, bufnr)
    require('utils.complete').configure(client, bufnr)
  end,
  cmd = function(_dispatchers)
    local members = {
      trace = 'messages',
      request = function(method, params, callback, notify_reply_callback)
        if handlers[method] then
          fire_and_forget(function()
            handlers[method](params, callback, notify_reply_callback)
          end)
        else
          -- fail silently
        end
      end,
      notify = function(_method, _params) end,
      is_closing = function() end,
      terminate = function() end,
    }

    return members
  end,
  root_markers = { '.git' },
  workspace_required = false,
}
