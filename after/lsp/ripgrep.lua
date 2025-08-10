---@module 'types.lsp_completion'
---@module 'cmp-rg.types'

local utils = {}
local split_keys = '., '
local triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz', '')

---@type rg.Source
local source = {} --[[@as any]]

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


---Check if keyword length criteria is met
---@param request AbstractContext
---@param keyword_length integer
---@return boolean
utils.minimum_keyword = function(request, keyword_length)
  local query = string.sub(request.context.cursor_before_line, request.offset)
  return #query >= keyword_length
end

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
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    table.insert(t, str)
  end
  return t
end


---Create a context data structure expected for cmp completion sources
---@param request LspRpcRequest
---@param option? AbstractContextOptionsRg
---@return AbstractContextRg
utils.create_abstracted_context = function(request, option)
  local line_num = request.position.line
  local col_num = request.position.character
  local buf = vim.uri_to_bufnr(request.textDocument.uri)
  local cursor_line = vim.api.nvim_get_current_line()
  local before_char = (request.context and request.context.triggerCharacter)
      or cursor_line:sub(col_num, col_num + 1)

  local cursor = { line_num, col_num }
  local cursor_before_line = string.sub(cursor_line, 1, col_num)
  local cursor_after_line = string.sub(cursor_line, col_num + 1)

  local context = {
    option = { reason =  request.context.triggerKind == 1 and 'manual' or 'auto' },
    filetype = vim.api.nvim_get_option_value('filetype', {
      buf = buf,
    }),
    time = vim.uv.now(),
    bufnr = buf,
    cursor_line = cursor_line,
    cursor = {
      row = cursor[1],
      col = cursor[2],
      line = cursor[1] - 1,
      character = utils.to_utfindex(cursor_line, col_num + 1),
    },
    get_reason = function(self_)
      return self_.option.reason
    end,
    cursor_before_line = cursor_before_line,
    cursor_after_line = cursor_after_line,
    before_char = before_char,
    -- throwaway values to appease some plugins that expect them (neorg)
    prev_context = {
      cursor = {
        row = request.position.line,
        col = col_num + 1,
      },
      line = cursor_line,
      line_before_cursor = cursor_line:sub(1, col_num + 1),
      bufnr = buf,
      before_char = before_char,
    },
  }

  -- yeah, maybe cache these? cmp does
  local offset = (function()
    -- if source.get_keyword_pattern then
    --   local pat = source:match_keyword_pattern(cursor_before_line)
    --   if pat then return pat end
    -- end
    -- return cursor[2] + 1
    local words_before_cursor = utils.split(cursor_before_line, split_keys)
    local last_word = words_before_cursor[#words_before_cursor]
    return math.max(col_num - #last_word + 1, 0)
  end)()

  return {
    id = utils.getId('rp.completion.new'),
    context = context,
    offset = offset,
    option = option or {},
    completion_context = {
      triggerKind = 0,
    },
  }
end

---@async
---@param co async fun() A fire-and-forget coroutine function
utils.fire_and_forget = function(co)
  coroutine.resume(coroutine.create(co))
end

---@param name string Name of source
---@return rg.Source
utils.create_source = function (name)
  ---@type { complete: function; display_name?: string; get_keyword_pattern: function; is_available?: function; match_keyword_pattern: function; name?: string } Name of source
  local cmp_source = require('lib.ripgrep').new()

  cmp_source.name = name
  cmp_source.display_name = name .. ' (cmp)'
  if not cmp_source.is_available then
    cmp_source.is_available = function()
      return true
    end
  end

  local old_complete = cmp_source.complete
  cmp_source.complete = function(self, completion_context, callback)
    old_complete(cmp_source, completion_context, function(response)
      if not response then
        callback({})
        return
      end
      if response.isIncomplete ~= nil then
        callback(response.items or {}, response.isIncomplete == true)
        return
      end
      callback(response.items or response)
    end)
  end

  local old_get_keyword_pattern = cmp_source.get_keyword_pattern
  if old_get_keyword_pattern then
    cmp_source.get_keyword_pattern = function(self, _)
      return old_get_keyword_pattern(self, { option = {} })
    end
  end

  cmp_source.match_keyword_pattern = function(self, line_before_cursor)
    return vim.regex([[\%(]] .. self:get_keyword_pattern() .. [[\)\m$]]):match_str(line_before_cursor)
  end

  -- local old_execute = cmp_source.execute
  -- if old_execute then
  --   cmp_source.execute = function(self, entry, _)
  --     old_execute(self, entry.completion_item, function() end)
  --   end
  -- end

  -- NOTE: I'm  removing the deepcopy b/c some sources store userdata values which cause deepcopy to
  -- throw an error. I don't think that it's really necessary, just a safety feature that Max
  -- included.
  -- sources.add_source(vim.deepcopy(cmp_source))

  return cmp_source
end

-- Create rg source
source = utils.create_source('rg')

-- _G.completion_test = {}

local handlers = {
  ['initialize'] = function(_params, callback, _notify_reply_callback)
    local initializeResult = {
      capabilities = {
        renameProvider = {
          prepareProvider = true,
        },
        completionProvider = {
          -- Explicit use only alphabetical characters
          triggerCharacters = triggerCharacters,
          -- triggerCharacters = {},
          resolveProvider = false,
          completionItem = {
            labelDetailsSupport = true,
          },
        },
      },
      serverInfo = {
        name = 'ripgrep',
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

    ---@type AbstractContextOptionsRg
    local option = vim.lsp.config.ripgrep.settings.option or {} --[[@as any]]
    local abstracted_context = utils.create_abstracted_context(request, option)
    local response = {}


    -- Only complete if minimum_keyword is reached
    if utils.minimum_keyword(abstracted_context, option.keyword_length or 0) then
      source:complete(abstracted_context, function(items)
        for _, item in ipairs(items) do
          item.kind = 1 -- complete kind is always text
          table.insert(response, item)
        end
      end)
    end

    -- table.insert(completion_test, {
    --   request = request,
    --   context = abstracted_context,
    --   option = option,
    --   satisfied = utils.minimum_keyword(abstracted_context, option.keyword_length or 0)
    --   -- response = response,
    -- })


    callback(nil, response)
  end,
}

---@type vim.lsp.Config
return {
  name = 'ripgrep',
  on_attach = function(client, bufnr)
    require('utils.lsp_maps').set_lsp_keys(client, bufnr)
    require('utils.complete').configure(client, bufnr, { triggerCharacters = triggerCharacters })
    -- require('utils.complete').configure(client, bufnr)
  end,
  cmd = function(_dispatchers)
    local members = {
      trace = 'messages',
      request = function(method, params, callback, notify_reply_callback)
        if handlers[method] then
          utils.fire_and_forget(function()
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
  settings = {
    ---@type AbstractContextOptionsRg
    option = {
      keyword_length = 3
    },
  },
}
