---@class rg.settings.base
---@field context_before integer lines for documentation preview before
---@field context_after integer lines for documentation preview after
---@field max_item_count integer|nil max number of results provided
---@field debug boolean whether to include additional logs or not
---@field debounce integer time to debounce search
---@field rg_flags? string[] additional flags to add to the rg command
---@field keyword_length integer minimum number of characters before starting a search
---@field rg_cmd string the command to use for ripgrep (defaults to 'rg')
---@field cache_ttl integer seconds to keep result in cache
---@field pattern string pattern to search matches with ripgrep

---@class rg.settings.user
---@field context_before? integer lines for documentation preview before
---@field context_after? integer lines for documentation preview after
---@field max_item_count? integer|nil max number of results provided
---@field debug? boolean whether to include additional logs or not
---@field debounce? integer time to debounce search
---@field rg_flags? string[] additional flags to add to the rg command
---@field keyword_length? integer minimum number of characters before starting a search
---@field rg_cmd? string the command to use for ripgrep (defaults to 'rg')
---@field cache_ttl? integer seconds to keep result in cache
---@field pattern? string pattern to search matches with ripgrep

---@alias rg.doc_cache table<string, { value: string; kind: string }>
---@alias rg.word_cache table<string, { time: integer; docs: rg.doc_cache; items: lsp.CompletionItem[] }>

---@class rg.settings
---@field rg rg.settings.user

---@alias rg.lsp.request.callback fun(err?: lsp.ResponseError, result: any, request_id: integer)
---@alias rg.lsp.notify.callback fun(request_id: integer)

local rg_ls = {}

local lsp_name = 'rg_ls'
local lsp_version = '0.0.1'
---@type rg.settings.base
local default_settings = {
  context_before = 1,
  context_after = 3,
  max_item_count = nil,
  debug = false,
  debounce = 100,
  rg_flags = {},
  keyword_length = 3,
  rg_cmd = 'rg',
  cache_ttl = 60,
  pattern ='[\\w_-]+',
}

local triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz', '')

local function get_word_before_cursor(line_text, character)
  local before_cursor = line_text:sub(1, character)
  return before_cursor:match('[%w_%-]+$') or ''
end

--- Create an in-process LSP server function compatible with vim.lsp.start({ cmd = ... })
---@param user_settings? rg.settings.user
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient
function rg_ls.create_server(user_settings)
  ---@type rg.settings.base
  local settings = vim.tbl_deep_extend('force', default_settings, user_settings or {})
  local message_id = 0

  return function(dispatchers)
    local closing = false
    local running_job_id = 0
    local uv = vim.uv or vim.loop
    local timer = assert(uv.new_timer())
    local doc_cache = {} ---@type rg.doc_cache
    local request_seq = 0
    local word_cache = {} ---@type rg.word_cache
    local root_dir = nil ---@type string|nil
    local last_asyn_req = {
      id = 0,
      job_id = 0,
    }

    ---Cleanup timer and ongoing job if any
    local function cleanup()
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      if running_job_id > 0 then
        pcall(vim.fn.jobstop, running_job_id)
        running_job_id = 0
      end
    end

    local function log(msg)
      if settings.debug then
        vim.schedule(function()
          vim.notify('[rg_lsp] ' .. msg, vim.log.levels.DEBUG)
        end)
      end
    end

    local handlers = {
      ---initialize handler
      ---@param params lsp.InitializeParams
      ---@param callback rg.lsp.request.callback
      ---@return boolean if request was successful
      ---@return integer message_id of the request
      ['initialize'] = function(params, callback)
        if params.rootUri and not (params.rootUri == vim.NIL) then
          root_dir = vim.uri_to_fname(params.rootUri --[[@as string]])
        elseif params.rootPath and not (params.rootPath == vim.NIL) then
          root_dir = params.rootPath --[[@as string]]
        end
        -- message_id = message_id + 1

        callback(nil, {
          capabilities = {
            completionProvider = {
              resolveProvider = true,
              triggerCharacters = triggerCharacters,
            },
            textDocumentSync = {
              openClose = true,
              change = 1,
            },
          },
          serverInfo = {
            name = lsp_name,
            version = lsp_version,
          },
        }, message_id)
        return true, message_id
      end,

      ---shutdown handler
      ---@param params {}
      ---@param callback rg.lsp.request.callback
      ---@return boolean if request was successful
      ---@return integer message_id of the request
      ['shutdown'] = function(params, callback)
        closing = true
        cleanup()
        message_id = message_id + 1
        callback(nil, nil, message_id)
        return true, message_id
      end,

      ---textDocument/Completion handler
      ---@param params lsp.TextDocumentPositionParams
      ---@param callback rg.lsp.request.callback
      ---@param notify rg.lsp.notify.callback
      ---@return boolean if request was successful
      ---@return integer message_id of the request
      ['textDocument/completion'] = function(params, callback, notify)
        local uri = params.textDocument.uri
        local bufnr = vim.uri_to_bufnr(uri)
        local line = params.position.line
        local character = params.position.character

        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)
        message_id = message_id + 1
        if not buf_lines or #buf_lines == 0 then
          callback(nil, { isIncomplete = false, items = {} }, message_id)
          notify(message_id)
          return true, message_id
        end

        local word = get_word_before_cursor(buf_lines[1], character)
        log("completion word: '" .. word .. "' (length: " .. #word .. ')')

        if #word < settings.keyword_length then
          callback(nil, { isIncomplete = false, items = {} }, message_id)
          notify(message_id)
          return true, message_id
        end

        if settings.cache_ttl > 0 then
          local cached = word_cache[word]
          if cached and (uv.now() - cached.time) < settings.cache_ttl * 1000 then
            log('cache hit for: ' .. word)
            doc_cache = cached.docs
            callback(nil, { isIncomplete = false, items = cached.items }, message_id)
            notify(message_id)
            return true, message_id
          end
        end

        request_seq = request_seq + 1
        local current_seq = request_seq

        timer:stop()
        if running_job_id > 0 then
          pcall(vim.fn.jobstop, running_job_id)
          running_job_id = 0
        end

        timer:start(
          settings.debounce,
          0,
          vim.schedule_wrap(function()
            if current_seq ~= request_seq then
              return
            end

            doc_cache = {}
            local seen = {}
            local items = {} ---@type lsp.CompletionItem[]
            local responded = false
            local context_before = settings.context_before
            local context_after = settings.context_after

            ---Send request response
            ---@param result { isIncomplete: boolean; items: lsp.CompletionItem[] }
            local function respond(result)
              if not responded and current_seq == request_seq then
                responded = true
                if settings.cache_ttl > 0 then
                  local now = uv.now()
                  local ttl_ms = settings.cache_ttl * 1000
                  for key, entry in pairs(word_cache) do
                    if (now - entry.time) >= ttl_ms then
                      word_cache[key] = nil
                    end
                  end

                  word_cache[word] = {
                    items = result.items,
                    docs = doc_cache,
                    time = now,
                  }
                end
                callback(nil, result, message_id)
                notify(message_id)
                return
              end
            end

            local function on_event(_, data, event)
              if event == 'stdout' then
                local messages = data

                local function get_message_with_lines(index)
                  if index < 1 then
                    return nil
                  end
                  local m = messages[index]
                  if not m then
                    return nil
                  end
                  if type(m) == 'string' then
                    local ok, decoded = pcall(vim.json.decode, m)
                    if not ok then
                      return nil
                    end
                    m, messages[index] = decoded, decoded
                  end
                  if m.type ~= 'match' and m.type ~= 'context' then
                    return nil
                  end
                  if not m.data or not m.data.lines or not m.data.lines.text then
                    return nil
                  end
                  m.data.lines.text = m.data.lines.text:gsub('\n', '')
                  return m
                end

                for current = 1, #data do
                  local message = get_message_with_lines(current)
                  if message and message.type == 'match' then
                    for _, submatch in ipairs(message.data.submatches) do
                      local label = submatch.match.text
                      if label and not seen[label] then
                        local path = message.data.path.text
                        local line_n = vim.tbl_get(message, 'data', 'line_number') or 0 ---@type number
                        local doc_lines = { path, ('line: %d'):format(line_n), '', '```' }
                        local doc_body = {}

                        if context_before > 0 then
                          for j = current - context_before, current - 1 do
                            local before = get_message_with_lines(j)
                            if before then
                              table.insert(doc_body, before.data.lines.text)
                            end
                          end
                        end

                        table.insert(doc_body, message.data.lines.text .. ' <--')

                        if context_after > 0 then
                          for k = current + 1, current + context_after do
                            local after = get_message_with_lines(k)
                            if after then
                              table.insert(doc_body, after.data.lines.text)
                            end
                          end
                        end

                        local min_indent = math.huge
                        for _, l in ipairs(doc_body) do
                          local _, indent = string.find(l, '^%s+')
                          min_indent = math.min(min_indent, indent or math.huge)
                        end
                        for _, l in ipairs(doc_body) do
                          table.insert(doc_lines, l:sub(min_indent))
                        end

                        table.insert(doc_lines, '```')
                        doc_cache[label] = {
                          value = table.concat(doc_lines, '\n'),
                          kind = 'markdown',
                        }

                        ---@type lsp.CompletionItem
                        local item = {
                          label = label,
                          data = { label = label },
                          kind = 1, -- Item kind 1 is 'Text'
                        }
                        table.insert(items, item)
                        seen[label] = true
                      end
                    end
                  end
                end

                if settings.max_item_count and #items >= settings.max_item_count then
                  pcall(vim.fn.jobstop, running_job_id)
                  running_job_id = 0
                  respond({ isIncomplete = false, items = items })
                  return
                end
              end

              if event == 'stderr' and settings.debug then
                vim.notify('[rg_lsp] ' .. table.concat(data, ''), vim.log.levels.ERROR)
              end

              if event == 'exit' then
                running_job_id = 0
                respond({ isIncomplete = false, items = items })
              end
            end

            local cmd = {
              settings.rg_cmd,
              '--heading',
              '--json',
              '--word-regexp',
              '-B',
              tostring(context_before),
              '-A',
              tostring(context_after),
              '--color',
              'never',
            }
            for _, flag in ipairs(settings.rg_flags) do
              table.insert(cmd, flag)
            end
            table.insert(cmd, word .. settings.pattern)
            table.insert(cmd, '.')

            log('cmd: ' .. table.concat(cmd, ' '))

            running_job_id = vim.fn.jobstart(cmd, {
              on_stderr = on_event,
              on_stdout = on_event,
              on_exit = on_event,
              cwd = root_dir or vim.fn.getcwd(),
            })

            if running_job_id <= 0 then
              last_asyn_req.job_id = running_job_id
              log('failed to start rg (job id: ' .. tostring(running_job_id) .. ')')
              respond({ isIncomplete = false, items = {} })
            end
          end)
        )
        last_asyn_req.id = message_id
        last_asyn_req.job_id = 0
        return true, message_id
      end,

      ---Lsp handler for completionItem/resolve
      ---@param params lsp.CompletionItem
      ---@param callback fun(err?: lsp.ResponseError, result?: lsp.CompletionItem, message_id: integer)
      ---@param notify rg.lsp.notify.callback
      ---@return boolean if request was successful
      ---@return integer message_id of the request
      ['completionItem/resolve'] = function(params, callback, notify)
        local item = params
        local label = item.data and item.data.label or item.label
        if doc_cache[label] then
          item.documentation = doc_cache[label]
        end
        message_id = message_id + 1
        callback(nil, item, message_id)
        notify(message_id)
        return true, message_id
      end,
    }

    return {
      ---Lsp request handler
      ---@param method vim.lsp.protocol.Method
      ---@param params any
      ---@param callback rg.lsp.request.callback
      ---@param notify_reply_callback rg.lsp.notify.callback
      ---@return boolean if request was successful
      ---@return integer message_id of the request
      request = function(method, params, callback, notify_reply_callback)
        if handlers[method] then
          return handlers[method](params, callback, notify_reply_callback)
        end
        -- message_id = message_id + 1
        callback({ code = 1, message = ('Method "%s" not supported'):format(method) }, nil, message_id)
        notify_reply_callback(message_id)
        return false, message_id
      end,

      ---Handle client notifications
      ---@param method 'exit'|'$/cancelRequest'|string
      ---@param params { id: number; }
      notify = function(method, params)
        if method == 'exit' then
          cleanup()
          dispatchers.on_exit(0, 0)
        elseif method == '$/cancelRequest' then
          -- It can only cancel 'textDocument/completion' as it 
          -- the only async method. All other will resolve synchornously
          if last_asyn_req.id == params.id then
            pcall(vim.fn.jobstop, last_asyn_req.job_id)
            running_job_id = 0
          end
        end
      end,


      is_closing = function()
        return closing
      end,

      terminate = function()
        closing = true
        cleanup()
      end,
    }
  end
end

--- Start the rg_ls server and attach the current buffer if possible
--- This is a small wrapper over `vim.lsp.start`
--- to start the server from anywhere
---@param user_settings? rg.settings.user
---@return integer? client_id
function rg_ls.start_server(user_settings)
  local client_id = vim.lsp.start({
    name = lsp_name,
    cmd = rg_ls.create_server(user_settings),
    root_dir = vim.fn.getcwd(),
  })

  if type(client_id) == 'number' then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.lsp.buf_attach_client(bufnr, client_id)
  end

  return client_id
end

---Function intended to be used for creating a server config
---under `<config>/lsp/rg_ls.lua` or `<config>/after/lsp/rg_ls.lua`
---@example
---```lua
---
---return {
---  name = 'rg_ls',
---  cmd = function(...)
---    return require('your_path').register(...)
---  end,
---  root_markers = { '.git' },
---  ---@type rg.settings.user
---  settings = { rg = {...} }, --- Your custom settings
---
---  ... -- Other custom options
---  on_attach = function(client, bufnr) end,
---  workspace_required = false,
---}
---```
---@param dispatchers vim.lsp.rpc.Dispatchers
---@param config vim.lsp.ClientConfig
---@returns vim.lsp.rpc.PublicClient
function rg_ls.register(dispatchers, config)
  local settings = vim.tbl_get(config, 'settings', 'rg') or {} --[[@as rg.settings.user]]
  local publicClient = rg_ls.create_server(settings)
  return publicClient(dispatchers)
end

return rg_ls
