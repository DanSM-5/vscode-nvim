---@class rg.settings.decorations
---@field after string|nil string to add after the content appended as a string. Default " <--"
---@field below string|nil char to use below the match. Default "─"

---@class rg.settings.base
---@field context_before integer lines for documentation preview before
---@field context_after integer lines for documentation preview after
---@field max_item_count integer|nil max number of results provided
---@field debug boolean whether to include additional logs or not
---@field debounce integer time to debounce search
---@field rg_flags string[] additional flags to add to the rg command
---@field keyword_length integer minimum number of characters before starting a search
---@field rg_cmd string the command to use for ripgrep (defaults to 'rg')
---@field cache_ttl integer seconds to keep result in cache
---@field pattern string pattern to search matches with ripgrep
---@field decorations rg.settings.decorations additional decorations for documentation preview
---@field ext_associations table<string, string> add/override associations for markdown code blocks

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
---@field ext_associations? table<string, string> add/override associations for markdown code blocks
---@field decorations? rg.settings.decorations additional decorations for documentation preview

---@alias rg.doc_cache table<string, { value: string; kind: string }>
---@alias rg.word_cache table<string, { time: integer; docs: rg.doc_cache; items: lsp.CompletionItem[] }>

---@class rg.settings
---@field rg rg.settings.user

---@alias rg.lsp.request.callback fun(err: lsp.ResponseError|nil, result: any, request_id: integer)
---@alias rg.lsp.notify.callback fun(request_id: integer)

---@class rg.lsp.pending_request
---@field id integer
---@field method string
---@field callback rg.lsp.request.callback
---@field notify_reply rg.lsp.notify.callback
---@field jobs table<integer, true>
---@field timer? uv.uv_timer_t
---@field done boolean

---@class rg.lsp.open_document
---@field uri lsp.DocumentUri
---@field text string
---@field version? integer

---@class rg.lsp.ToggleReferencesParams
---@field enabled? boolean Toggle when omitted; otherwise force this state.

---@class rg.lsp.ToggleReferencesResult
---@field enabled boolean The resulting state for this rg_ls client.

---@class rg.json.Text
---@field text? string

---@class rg.json.Submatch
---@field match rg.json.Text
---@field start integer Zero-based UTF-8 byte offset.
---@field end integer Exclusive zero-based UTF-8 byte offset.

---@class rg.json.Data
---@field path? rg.json.Text
---@field lines? rg.json.Text
---@field line_number? integer One-based line number.
---@field submatches? rg.json.Submatch[]

---@class rg.json.Message
---@field type string
---@field data? rg.json.Data

---@class rg.json.Stream
---@field tail string

local rg_ls = {}

local lsp_name = 'rg_ls'
local lsp_version = '0.1.0'
local toggle_references_method = 'rg_ls/toggleReferences'
local references_method = 'textDocument/references'
local references_registration_id = 'rg_ls.references'
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
  pattern = '[\\w_-]+',
  ext_associations = {},
  decorations = {
    after = ' <--',
    below = '─',
  },
}
-- Default trigger chars
local triggerCharacters = vim.split('abcdefghijklmnopqrstuvwxyz', '')

--- For markdown code fence
local extension_to_lang = {
  default = 'text', -- when no idea 🤷‍♂️

  -- Programming Languages
  ['py'] = 'python',
  ['js'] = 'javascript',
  ['mjs'] = 'javascript',
  ['ts'] = 'typescript',
  ['tsx'] = 'tsx',
  ['jsx'] = 'jsx',
  ['rb'] = 'ruby',
  ['cpp'] = 'cpp',
  ['hpp'] = 'cpp',
  ['c'] = 'c',
  ['h'] = 'c',
  ['cs'] = 'csharp',
  ['vim'] = 'vim',
  ['java'] = 'java',
  ['go'] = 'go',
  ['rs'] = 'rust',
  ['lua'] = 'lua',
  ['php'] = 'php',
  ['swift'] = 'swift',
  ['kt'] = 'kotlin',
  ['dart'] = 'dart',
  ['ex'] = 'elixir',
  ['exs'] = 'elixir',
  ['erl'] = 'erlang',
  ['hs'] = 'haskell',
  ['clj'] = 'clojure',
  ['scala'] = 'scala',

  -- Web / Markup
  ['html'] = 'html',
  ['css'] = 'css',
  ['scss'] = 'scss',
  ['less'] = 'less',
  ['md'] = 'markdown',
  ['mdx'] = 'tsx',
  ['xml'] = 'xml',
  ['svg'] = 'xml',

  -- Config / Data
  ['json'] = 'json',
  ['jsonc'] = 'jsonc',
  ['yaml'] = 'yaml',
  ['yml'] = 'yaml',
  ['toml'] = 'toml',
  ['ini'] = 'ini',
  ['sql'] = 'sql',

  -- Scripts / Shell
  ['sh'] = 'bash',
  ['bash'] = 'bash',
  ['zsh'] = 'bash',
  ['ps1'] = 'powershell',
  ['bat'] = 'batch',
  ['cmd'] = 'batch',
  ['vbs'] = 'vbs',

  -- Infrastructure
  ['dockerfile'] = 'dockerfile', -- Special case for filenames
  ['tf'] = 'hcl', -- Terraform
  ['makefile'] = 'makefile',

  -- Git related
  ['git'] = 'git',
  ['patch'] = 'diff',
  ['diff'] = 'diff',
  ['gitignore'] = 'ignore',
  ['gitconfig'] = 'gitconfig',
  ['gitattributes'] = 'gitattributes',
  ['gitmodules'] = 'gitconfig', -- Uses same syntax as .gitconfig
  ['mailmap'] = 'text',
}

---Get language of the file
---@param file string
local function get_lang(file)
  local ext = vim.fs.ext(file)

  -- Probably a dotfile (e.g. ".gitignore") or
  -- a file without extension (e.g. "Dockerfile")
  if ext == '' then
    ext = vim.fs.basename(file)
    if vim.startswith(ext, '.') then
      ext = ext:gsub(vim.pesc('.'), '')
    end
  end

  -- Could not find suitable extension
  if ext == '' then
    return extension_to_lang.default
  end

  ext = string.lower(ext)
  return extension_to_lang[ext] or extension_to_lang.default
end

---Add or replace extension-to-language mappings for completion documentation.
---@param associations table<string, string>
local function update_file_associations(associations)
  for ext, lang in pairs(associations) do
    extension_to_lang[ext] = lang
  end
end

---Get the word immediately before a zero-based UTF-8 byte offset.
---@param line_text string
---@param byte_offset integer
---@return string
local function get_word_before_cursor(line_text, byte_offset)
  local before_cursor = line_text:sub(1, byte_offset)
  return before_cursor:match('[%w_%-]+$') or ''
end

---Whether a byte is part of the broad identifier syntax used by this fallback.
---Non-ASCII bytes are kept together so that UTF-8 identifiers remain searchable.
---@param byte? integer
---@return boolean
local function is_symbol_byte(byte)
  return byte ~= nil
    and (
      byte >= 128
      or byte == 45
      or byte == 95
      or byte >= 48 and byte <= 57
      or byte >= 65 and byte <= 90
      or byte >= 97 and byte <= 122
    )
end

---Get the broad identifier containing a zero-based UTF-8 byte offset.
---@param line_text string
---@param byte_offset integer
---@return string
local function get_word_at_cursor(line_text, byte_offset)
  byte_offset = math.max(0, math.min(byte_offset, #line_text))
  local anchor = byte_offset + 1
  if not is_symbol_byte(line_text:byte(anchor)) and byte_offset > 0 then
    anchor = byte_offset
  end
  if not is_symbol_byte(line_text:byte(anchor)) then
    return ''
  end

  local first = anchor
  while first > 1 and is_symbol_byte(line_text:byte(first - 1)) do
    first = first - 1
  end

  local last = anchor
  while last < #line_text and is_symbol_byte(line_text:byte(last + 1)) do
    last = last + 1
  end
  return line_text:sub(first, last)
end

---Consume complete newline-delimited JSON objects from a job callback.
---@param stream rg.json.Stream
---@param data string[]
---@param on_message fun(message: rg.json.Message)
local function consume_json_lines(stream, data, on_message)
  if #data == 0 then
    return
  end

  for index, chunk in ipairs(data) do
    if index == 1 then
      chunk = stream.tail .. chunk
    end
    if index == #data then
      stream.tail = chunk
    elseif chunk ~= '' then
      local ok, message = pcall(vim.json.decode, chunk)
      if ok and type(message) == 'table' then
        on_message(message --[[@as rg.json.Message]])
      end
    end
  end
end

---Flush the final unterminated JSON object from a job stream.
---@param stream rg.json.Stream
---@param on_message fun(message: rg.json.Message)
local function flush_json_lines(stream, on_message)
  if stream.tail == '' then
    return
  end
  local line = stream.tail
  stream.tail = ''
  local ok, message = pcall(vim.json.decode, line)
  if ok and type(message) == 'table' then
    on_message(message --[[@as rg.json.Message]])
  end
end

---Create an in-process LSP server compatible with `vim.lsp.start({ cmd = ... })`.
---@param user_settings? rg.settings.user
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient
function rg_ls.create_server(user_settings)
  user_settings = user_settings or {}
  ---@type rg.settings.base
  local settings = vim.tbl_deep_extend('force', default_settings, user_settings)
  settings.decorations = vim.tbl_deep_extend('force', default_settings.decorations, user_settings.decorations or {})
  update_file_associations(settings.ext_associations)

  return function(dispatchers)
    local closing = false
    local exit_dispatched = false
    local message_id = 0
    local root_dir = nil ---@type string|nil
    local references_enabled = false
    local dynamic_references_supported = false
    local latest_completion_id = nil ---@type integer|nil
    local uv = vim.uv or vim.loop
    local doc_cache = {} ---@type rg.doc_cache
    local word_cache = {} ---@type rg.word_cache
    local pending_requests = {} ---@type table<integer, rg.lsp.pending_request>
    local open_documents = {} ---@type table<lsp.DocumentUri, rg.lsp.open_document>

    ---Log a debug message without calling `vim.notify` from a fast event.
    ---@param message string
    local function log(message)
      if settings.debug then
        vim.schedule(function()
          vim.notify('[rg_ls] ' .. message, vim.log.levels.DEBUG)
        end)
      end
    end

    ---Close a request's debounce timer.
    ---@param request rg.lsp.pending_request
    local function close_timer(request)
      local timer = request.timer
      request.timer = nil
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end

    ---Settle an LSP request exactly once.
    ---@param request rg.lsp.pending_request
    ---@param err lsp.ResponseError|nil
    ---@param result any
    ---@param stop_jobs? boolean
    ---@return boolean settled
    local function settle_request(request, err, result, stop_jobs)
      if request.done then
        return false
      end

      request.done = true
      pending_requests[request.id] = nil
      if latest_completion_id == request.id then
        latest_completion_id = nil
      end
      close_timer(request)

      if stop_jobs then
        local jobs = request.jobs
        request.jobs = {}
        for job_id in pairs(jobs) do
          pcall(vim.fn.jobstop, job_id)
        end
      end

      local notify_ok, notify_err = pcall(request.notify_reply, request.id)
      local callback_ok, callback_err = pcall(request.callback, err, result, request.id)
      if not notify_ok then
        dispatchers.on_error(vim.lsp.rpc.client_errors.SERVER_RESULT_CALLBACK_ERROR, notify_err)
      end
      if not callback_ok then
        dispatchers.on_error(vim.lsp.rpc.client_errors.SERVER_RESULT_CALLBACK_ERROR, callback_err)
      end
      return true
    end

    ---Cancel an asynchronous request and acknowledge the cancellation.
    ---@param request rg.lsp.pending_request
    ---@param reason? string
    local function cancel_request(request, reason)
      settle_request(
        request,
        {
          code = vim.lsp.protocol.ErrorCodes.RequestCancelled,
          message = reason or 'Request cancelled',
        },
        nil,
        true
      )
    end

    ---Cancel all currently pending requests.
    ---@param reason string
    ---@param method? string Restrict cancellation to this method.
    local function cancel_pending_requests(reason, method)
      local requests = {} ---@type rg.lsp.pending_request[]
      for _, request in pairs(pending_requests) do
        if not method or request.method == method then
          requests[#requests + 1] = request
        end
      end
      for _, request in ipairs(requests) do
        cancel_request(request, reason)
      end
    end

    ---Stop all work owned by the server.
    ---@param reason string
    local function cleanup(reason)
      cancel_pending_requests(reason)
    end

    ---Track an asynchronous request so that `$/cancelRequest` can find it.
    ---@param request rg.lsp.pending_request
    local function track_request(request)
      pending_requests[request.id] = request
    end

    ---Respond to completion and update the completion documentation cache.
    ---@param request rg.lsp.pending_request
    ---@param word string
    ---@param docs rg.doc_cache
    ---@param items lsp.CompletionItem[]
    ---@param stop_jobs? boolean
    local function complete_completion(request, word, docs, items, stop_jobs)
      if request.done then
        return
      end

      doc_cache = docs
      if settings.cache_ttl > 0 then
        local now = uv.now()
        local ttl_ms = settings.cache_ttl * 1000
        for key, entry in pairs(word_cache) do
          if now - entry.time >= ttl_ms then
            word_cache[key] = nil
          end
        end
        word_cache[word] = { items = items, docs = docs, time = now }
      end

      settle_request(request, nil, { isIncomplete = false, items = items }, stop_jobs)
    end

    ---Run the asynchronous completion search after its debounce period.
    ---@param request rg.lsp.pending_request
    ---@param word string
    local function start_completion_search(request, word)
      if request.done then
        return
      end

      local seen = {} ---@type table<string, true>
      local items = {} ---@type lsp.CompletionItem[]
      local docs = {} ---@type rg.doc_cache
      local context_before = settings.context_before
      local context_after = settings.context_after

      ---@param messages (string|rg.json.Message)[]
      ---@param index integer
      ---@return rg.json.Message?
      local function get_message_with_lines(messages, index)
        if index < 1 then
          return nil
        end
        local message = messages[index]
        if not message then
          return nil
        end
        if type(message) == 'string' then
          local ok, decoded = pcall(vim.json.decode, message)
          if not ok or type(decoded) ~= 'table' then
            return nil
          end
          message = decoded --[[@as rg.json.Message]]
          messages[index] = message
        end
        if message.type ~= 'match' and message.type ~= 'context' then
          return nil
        end
        local data = message.data
        if not data or not data.lines or not data.lines.text then
          return nil
        end
        data.lines.text = data.lines.text:gsub('\n$', ''):gsub('\r$', '')
        return message
      end

      ---@param _ integer
      ---@param data string[]
      local function on_stdout(_, data)
        if request.done then
          return
        end
        ---@type (string|rg.json.Message)[]
        local messages = data
        for current = 1, #messages do
          local message = get_message_with_lines(messages, current)
          local message_data = message and message.data or nil
          if message and message.type == 'match' and message_data and message_data.submatches then
            for _, submatch in ipairs(message_data.submatches) do
              local label = submatch.match.text
              local path = message_data.path and message_data.path.text or nil
              if label and not seen[label] and path then
                local line_number = message_data.line_number or 0
                local doc_lines = { path, ('line: %d'):format(line_number), '', '```' .. get_lang(path) }
                local doc_body = {} ---@type string[]

                for index = current - context_before, current - 1 do
                  local context = get_message_with_lines(messages, index)
                  if context and context.data and context.data.lines and context.data.lines.text then
                    doc_body[#doc_body + 1] = context.data.lines.text
                  end
                end

                local decorations = settings.decorations
                doc_body[#doc_body + 1] = message_data.lines.text .. (decorations.after or '')
                if decorations.below and decorations.below ~= '' then
                  doc_body[#doc_body + 1] = string.rep(' ', submatch.start)
                    .. string.rep(decorations.below, submatch['end'] - submatch.start)
                end

                for index = current + 1, current + context_after do
                  local context = get_message_with_lines(messages, index)
                  if context and context.data and context.data.lines and context.data.lines.text then
                    doc_body[#doc_body + 1] = context.data.lines.text
                  end
                end

                local min_indent = math.huge
                for _, line_text in ipairs(doc_body) do
                  local _, indent = string.find(line_text, '^%s+')
                  min_indent = math.min(min_indent, indent or math.huge)
                end
                for _, line_text in ipairs(doc_body) do
                  doc_lines[#doc_lines + 1] = line_text:sub(min_indent)
                end
                doc_lines[#doc_lines + 1] = '```'

                docs[label] = { value = table.concat(doc_lines, '\n'), kind = 'markdown' }
                items[#items + 1] = {
                  label = label,
                  data = { label = label },
                  kind = vim.lsp.protocol.CompletionItemKind.Text,
                }
                seen[label] = true
              end
            end
          end
        end

        if settings.max_item_count and #items >= settings.max_item_count then
          complete_completion(request, word, docs, items, true)
        end
      end

      ---@param _ integer
      ---@param data string[]
      local function on_stderr(_, data)
        if settings.debug then
          log(table.concat(data, ''))
        end
      end

      ---@param job_id integer
      local function on_exit(job_id)
        request.jobs[job_id] = nil
        complete_completion(request, word, docs, items)
      end

      local command = {
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
      vim.list_extend(command, settings.rg_flags)
      command[#command + 1] = '--'
      command[#command + 1] = word .. settings.pattern
      command[#command + 1] = '.'
      log('cmd: ' .. table.concat(command, ' '))

      local job_id = vim.fn.jobstart(command, {
        cwd = root_dir or vim.fn.getcwd(),
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit,
      })
      if job_id <= 0 then
        log('failed to start rg (job id: ' .. tostring(job_id) .. ')')
        complete_completion(request, word, docs, items)
        return
      end
      request.jobs[job_id] = true
    end

    ---Handle `textDocument/completion`.
    ---@param params lsp.TextDocumentPositionParams
    ---@param request rg.lsp.pending_request
    local function handle_completion(params, request)
      local uri = params.textDocument.uri
      local bufnr = vim.uri_to_bufnr(uri)
      local line_number = params.position.line
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        settle_request(request, nil, { isIncomplete = false, items = {} })
        return
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, line_number, line_number + 1, false)
      if #lines == 0 then
        settle_request(request, nil, { isIncomplete = false, items = {} })
        return
      end

      local byte_offset = vim.str_byteindex(lines[1], 'utf-16', params.position.character, false)
      local word = get_word_before_cursor(lines[1], byte_offset)
      log("completion word: '" .. word .. "' (length: " .. #word .. ')')
      if #word < settings.keyword_length then
        settle_request(request, nil, { isIncomplete = false, items = {} })
        return
      end

      if settings.cache_ttl > 0 then
        local cached = word_cache[word]
        if cached and uv.now() - cached.time < settings.cache_ttl * 1000 then
          doc_cache = cached.docs
          settle_request(request, nil, { isIncomplete = false, items = cached.items })
          return
        end
      end

      if latest_completion_id then
        local previous = pending_requests[latest_completion_id]
        if previous then
          cancel_request(previous, 'Superseded by a newer completion request')
        end
      end
      latest_completion_id = request.id
      track_request(request)

      local timer = uv.new_timer()
      if not timer then
        settle_request(
          request,
          { code = vim.lsp.protocol.ErrorCodes.InternalError, message = 'Could not create completion timer' },
          nil
        )
        return
      end
      request.timer = timer
      timer:start(
        settings.debounce,
        0,
        vim.schedule_wrap(function()
          close_timer(request)
          start_completion_search(request, word)
        end)
      )
    end

    ---Resolve a ripgrep path to an absolute file URI.
    ---@param path string
    ---@param cwd string
    ---@return lsp.DocumentUri
    local function path_to_uri(path, cwd)
      path = vim.fs.normalize(path)
      if vim.fs.abspath(path) ~= path then
        path = vim.fs.normalize(vim.fs.joinpath(cwd, path))
      end
      return vim.uri_from_fname(path)
    end

    ---Handle `textDocument/references` asynchronously.
    ---@param params lsp.ReferenceParams
    ---@param request rg.lsp.pending_request
    local function handle_references(params, request)
      if not references_enabled then
        settle_request(request, nil, nil)
        return
      end

      local request_uri = params.textDocument.uri
      local request_bufnr = vim.uri_to_bufnr(request_uri)
      local request_line = params.position.line
      local line_text = nil ---@type string|nil
      if vim.api.nvim_buf_is_loaded(request_bufnr) then
        line_text = vim.api.nvim_buf_get_lines(request_bufnr, request_line, request_line + 1, false)[1]
      end
      if not line_text then
        local document = open_documents[request_uri]
        if document then
          line_text = vim.split(document.text, '\n', { plain = true })[request_line + 1]
        end
      end
      if not line_text then
        settle_request(request, nil, {})
        return
      end

      local request_byte = vim.str_byteindex(line_text, 'utf-16', params.position.character, false)
      local word = get_word_at_cursor(line_text, request_byte)
      if word == '' then
        settle_request(request, nil, {})
        return
      end

      local include_declaration = not params.context or params.context.includeDeclaration ~= false
      local cwd = root_dir or vim.fn.getcwd()
      local locations = {} ---@type lsp.Location[]
      local seen = {} ---@type table<string, true>
      local snapshots = {} ---@type table<lsp.DocumentUri, string>
      for uri, document in pairs(open_documents) do
        snapshots[uri] = document.text
      end
      if not snapshots[request_uri] and vim.api.nvim_buf_is_loaded(request_bufnr) then
        snapshots[request_uri] = table.concat(vim.api.nvim_buf_get_lines(request_bufnr, 0, -1, false), '\n')
      end

      ---Add locations from one ripgrep JSON match record.
      ---@param message rg.json.Message
      ---@param forced_uri? lsp.DocumentUri URI for a document searched over stdin.
      local function add_match(message, forced_uri)
        if message.type ~= 'match' then
          return
        end
        local data = message.data
        if not data then
          return
        end
        local lines = data.lines
        local line_number = data.line_number
        local submatches = data.submatches
        local match_line = lines and lines.text or nil
        if type(match_line) ~= 'string' or type(line_number) ~= 'number' or not submatches then
          return
        end

        local uri = forced_uri
        if not uri then
          local path_data = data.path
          local path = path_data and path_data.text or nil
          if not path then
            return
          end
          uri = path_to_uri(path, cwd)
          if snapshots[uri] then
            return
          end
        end

        local zero_based_line = line_number - 1
        for _, submatch in ipairs(submatches) do
          local start_byte = submatch.start
          local end_byte = submatch['end']
          local is_origin = uri == request_uri
            and zero_based_line == request_line
            and start_byte <= request_byte
            and request_byte < end_byte
          if include_declaration or not is_origin then
            local start_character = vim.str_utfindex(match_line, 'utf-16', start_byte, false)
            local end_character = vim.str_utfindex(match_line, 'utf-16', end_byte, false)
            local key = table.concat({ uri, zero_based_line, start_character, end_character }, ':')
            if not seen[key] then
              seen[key] = true
              locations[#locations + 1] = {
                uri = uri,
                range = {
                  start = { line = zero_based_line, character = start_character },
                  ['end'] = { line = zero_based_line, character = end_character },
                },
              }
            end
          end
        end
      end

      local remaining_jobs = 0
      local all_jobs_started = false

      local function finish_if_ready()
        if request.done or not all_jobs_started or remaining_jobs ~= 0 then
          return
        end
        table.sort(locations, function(left, right)
          if left.uri ~= right.uri then
            return left.uri < right.uri
          end
          if left.range.start.line ~= right.range.start.line then
            return left.range.start.line < right.range.start.line
          end
          return left.range.start.character < right.range.start.character
        end)
        settle_request(request, nil, locations)
      end

      ---Fail the reference request and stop every remaining ripgrep process.
      ---@param message string
      local function fail(message)
        settle_request(
          request,
          { code = vim.lsp.protocol.ErrorCodes.InternalError, message = message },
          nil,
          true
        )
      end

      ---Start one ripgrep process and aggregate its JSON matches.
      ---@param target string
      ---@param stdin_text? string
      ---@param forced_uri? lsp.DocumentUri
      local function start_reference_job(target, stdin_text, forced_uri)
        if request.done then
          return
        end

        local command = {
          settings.rg_cmd,
          '--json',
          '--fixed-strings',
          '--word-regexp',
          '--color',
          'never',
        }
        vim.list_extend(command, settings.rg_flags)
        command[#command + 1] = '--'
        command[#command + 1] = word
        command[#command + 1] = target
        log('cmd: ' .. table.concat(command, ' '))

        local stdout = { tail = '' } ---@type rg.json.Stream
        local stderr = {} ---@type string[]
        remaining_jobs = remaining_jobs + 1
        local job_id = vim.fn.jobstart(command, {
          cwd = cwd,
          on_stdout = function(_, data)
            if not request.done then
              consume_json_lines(stdout, data, function(message)
                add_match(message, forced_uri)
              end)
            end
          end,
          on_stderr = function(_, data)
            for _, chunk in ipairs(data) do
              if chunk ~= '' then
                stderr[#stderr + 1] = chunk
              end
            end
          end,
          on_exit = function(exited_job_id, exit_code)
            request.jobs[exited_job_id] = nil
            if request.done then
              return
            end
            flush_json_lines(stdout, function(message)
              add_match(message, forced_uri)
            end)
            remaining_jobs = remaining_jobs - 1
            if exit_code > 1 then
              local detail = #stderr > 0 and table.concat(stderr, '\n') or ('exit code ' .. exit_code)
              fail('ripgrep reference search failed: ' .. detail)
              return
            end
            finish_if_ready()
          end,
        })

        if job_id <= 0 then
          remaining_jobs = remaining_jobs - 1
          fail('Could not start ripgrep reference search (job id: ' .. job_id .. ')')
          return
        end
        request.jobs[job_id] = true
        if stdin_text ~= nil then
          local sent = vim.fn.chansend(job_id, stdin_text)
          vim.fn.chanclose(job_id, 'stdin')
          if sent == 0 then
            fail('Could not send an open document to ripgrep')
          end
        end
      end

      track_request(request)
      start_reference_job('.')
      for uri, text in pairs(snapshots) do
        if text ~= '' then
          start_reference_job('-', text, uri)
        end
      end
      all_jobs_started = true
      finish_if_ready()
    end

    ---Toggle the dynamically registered reference capability.
    ---@param params rg.lsp.ToggleReferencesParams
    ---@param request rg.lsp.pending_request
    local function handle_toggle_references(params, request)
      if params.enabled ~= nil and type(params.enabled) ~= 'boolean' then
        settle_request(
          request,
          { code = vim.lsp.protocol.ErrorCodes.InvalidParams, message = '`enabled` must be true or false' },
          nil
        )
        return
      end

      local enabled = params.enabled
      if enabled == nil then
        enabled = not references_enabled
      end
      if enabled == references_enabled then
        settle_request(request, nil, { enabled = references_enabled } --[[@as rg.lsp.ToggleReferencesResult]])
        return
      end

      if enabled then
        if not dynamic_references_supported then
          settle_request(
            request,
            {
              code = vim.lsp.protocol.ErrorCodes.RequestFailed,
              message = 'The client did not enable dynamic registration for references',
            },
            nil
          )
          return
        end
        ---@type lsp.RegistrationParams
        local registration = {
          registrations = {
            {
              id = references_registration_id,
              method = references_method,
              registerOptions = { documentSelector = vim.NIL },
            },
          },
        }
        local _, err = dispatchers.server_request('client/registerCapability', registration)
        if err then
          settle_request(request, err, nil)
          return
        end
        references_enabled = true
      else
        references_enabled = false
        cancel_pending_requests('Reference capability disabled', references_method)
        ---@type lsp.UnregistrationParams
        local unregistration = {
          unregisterations = {
            { id = references_registration_id, method = references_method },
          },
        }
        local _, err = dispatchers.server_request('client/unregisterCapability', unregistration)
        if err then
          settle_request(request, err, nil)
          return
        end
      end

      settle_request(request, nil, { enabled = references_enabled } --[[@as rg.lsp.ToggleReferencesResult]])
    end

    ---@alias rg.lsp.handler fun(params: any, request: rg.lsp.pending_request)
    ---@type table<string, rg.lsp.handler>
    local handlers = {
      ['initialize'] = function(params, request)
        params = params --[[@as lsp.InitializeParams]]
        if params.rootUri and params.rootUri ~= vim.NIL then
          root_dir = vim.uri_to_fname(params.rootUri --[[@as string]])
        elseif params.rootPath and params.rootPath ~= vim.NIL then
          root_dir = params.rootPath --[[@as string]]
        end
        dynamic_references_supported = vim.tbl_get(
          params,
          'capabilities',
          'textDocument',
          'references',
          'dynamicRegistration'
        ) == true

        ---@type lsp.InitializeResult
        local result = {
          capabilities = {
            completionProvider = {
              resolveProvider = true,
              triggerCharacters = triggerCharacters,
            },
            positionEncoding = 'utf-16',
            textDocumentSync = {
              openClose = true,
              change = vim.lsp.protocol.TextDocumentSyncKind.Full,
              save = { includeText = true },
            },
          },
          serverInfo = { name = lsp_name, version = lsp_version },
        }
        settle_request(request, nil, result)
      end,

      ['shutdown'] = function(_, request)
        closing = true
        cleanup('Server shutting down')
        settle_request(request, nil, nil)
      end,

      ['textDocument/completion'] = function(params, request)
        handle_completion(params --[[@as lsp.TextDocumentPositionParams]], request)
      end,

      ['completionItem/resolve'] = function(params, request)
        local item = params --[[@as lsp.CompletionItem]]
        local label = item.data and item.data.label or item.label
        if doc_cache[label] then
          item.documentation = doc_cache[label]
        end
        settle_request(request, nil, item)
      end,

      [references_method] = function(params, request)
        handle_references(params --[[@as lsp.ReferenceParams]], request)
      end,

      [toggle_references_method] = function(params, request)
        handle_toggle_references(params --[[@as rg.lsp.ToggleReferencesParams]], request)
      end,
    }

    ---@type vim.lsp.rpc.PublicClient
    local public_client = {
      ---Handle a request sent by Neovim to the in-process server.
      ---@param method vim.lsp.protocol.Method.ClientToServer.Request|string
      ---@param params table?
      ---@param callback rg.lsp.request.callback
      ---@param notify_reply_callback? rg.lsp.notify.callback
      ---@return boolean success
      ---@return integer? request_id
      request = function(method, params, callback, notify_reply_callback)
        if closing then
          return false, nil
        end

        message_id = message_id + 1
        ---@type rg.lsp.pending_request
        local request = {
          id = message_id,
          method = method,
          callback = callback,
          notify_reply = notify_reply_callback or function() end,
          jobs = {},
          done = false,
        }

        local handler = handlers[method]
        if not handler then
          settle_request(
            request,
            {
              code = vim.lsp.protocol.ErrorCodes.MethodNotFound,
              message = ('Method "%s" is not supported'):format(method),
            },
            nil
          )
          return true, request.id
        end

        local ok, err = pcall(handler, params or {}, request)
        if not ok then
          settle_request(
            request,
            { code = vim.lsp.protocol.ErrorCodes.InternalError, message = tostring(err) },
            nil,
            true
          )
        end
        return true, request.id
      end,

      ---Handle a notification sent by Neovim to the in-process server.
      ---@param method vim.lsp.protocol.Method.ClientToServer.Notification|string
      ---@param params table?
      ---@return boolean success
      notify = function(method, params)
        params = params or {}
        if method == 'exit' then
          closing = true
          cleanup('Server exited')
          if not exit_dispatched then
            exit_dispatched = true
            dispatchers.on_exit(0, 0)
          end
        elseif method == '$/cancelRequest' then
          local request_id = params.id
          local request = type(request_id) == 'number' and pending_requests[request_id] or nil
          if request then
            cancel_request(request)
          end
        elseif method == 'textDocument/didOpen' then
          local notification = params --[[@as lsp.DidOpenTextDocumentParams]]
          local document = notification.textDocument
          open_documents[document.uri] = {
            uri = document.uri,
            text = document.text,
            version = document.version,
          }
        elseif method == 'textDocument/didChange' then
          local notification = params --[[@as lsp.DidChangeTextDocumentParams]]
          local document = open_documents[notification.textDocument.uri]
          local change = notification.contentChanges[#notification.contentChanges]
          if document and change and change.range == nil then
            document.text = change.text
            document.version = notification.textDocument.version
          end
        elseif method == 'textDocument/didSave' then
          local notification = params --[[@as lsp.DidSaveTextDocumentParams]]
          local document = open_documents[notification.textDocument.uri]
          if document and notification.text then
            document.text = notification.text
          end
        elseif method == 'textDocument/didClose' then
          local notification = params --[[@as lsp.DidCloseTextDocumentParams]]
          open_documents[notification.textDocument.uri] = nil
        end
        return true
      end,

      ---@return boolean
      is_closing = function()
        return closing
      end,

      terminate = function()
        closing = true
        cleanup('Server terminated')
      end,
    }
    return public_client
  end
end

---Resolve the rg_ls client targeted by an `RgLsToggle` invocation.
---@param bufnr integer
---@param count integer Zero means that no explicit client ID was supplied.
---@return vim.lsp.Client?
local function resolve_toggle_client(bufnr, count)
  if count > 0 then
    local client = vim.lsp.get_client_by_id(count)
    if client and client.name == lsp_name and not client:is_stopped() then
      return client
    end
    return nil
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = lsp_name })
  table.sort(clients, function(left, right)
    return left.id < right.id
  end)
  return clients[1]
end

---Install the buffer-local `RgLsToggle` command for an attached rg_ls client.
---
---A command count targets that exact client ID (`:24RgLsToggle`). Without a
---count, the first rg_ls client attached to the buffer is used. Missing clients
---are deliberately a no-op.
---@param client vim.lsp.Client
---@param bufnr integer
function rg_ls.on_attach(client, bufnr)
  if client.name ~= lsp_name then
    return
  end

  vim.api.nvim_buf_create_user_command(bufnr, 'RgLsToggle', function(command)
    local target = resolve_toggle_client(bufnr, command.count)
    if not target then
      return
    end

    local enabled = nil ---@type boolean|nil
    if command.args ~= '' then
      if command.args == 'true' then
        enabled = true
      elseif command.args == 'false' then
        enabled = false
      else
        vim.notify('RgLsToggle expects true or false', vim.log.levels.ERROR)
        return
      end
    end

    ---@type rg.lsp.ToggleReferencesParams
    local params = { enabled = enabled }
    local request_bufnr = target.attached_buffers[bufnr] and bufnr or next(target.attached_buffers) or bufnr
    target:request(
      toggle_references_method --[[@as vim.lsp.protocol.Method.ClientToServer.Request]],
      params,
      function(err, result)
        if err then
          vim.notify('[rg_ls] ' .. err.message, vim.log.levels.ERROR)
          return
        end
        result = result --[[@as rg.lsp.ToggleReferencesResult]]
        vim.notify(('[rg_ls] references %s'):format(result.enabled and 'enabled' or 'disabled'))
      end,
      request_bufnr
    )
  end, {
    count = 0,
    desc = 'Toggle ripgrep reference results for an rg_ls client',
    force = true,
    nargs = '?',
    complete = function(arg_lead)
      return vim.tbl_filter(function(value)
        return vim.startswith(value, arg_lead)
      end, { 'true', 'false' })
    end,
  })
end

--- Start the rg_ls server and attach the current buffer if possible
--- This is a small wrapper over `vim.lsp.start`
--- to start the server from anywhere
---@param user_settings? rg.settings.user
---@return integer? client_id
function rg_ls.start_server(user_settings)
  local client_id = vim.lsp.start({
    name = lsp_name,
    cmd = rg_ls.create_server(user_settings or {}),
    on_attach = rg_ls.on_attach,
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
---@return vim.lsp.rpc.PublicClient
function rg_ls.register(dispatchers, config)
  local settings = vim.tbl_get(config, 'settings', 'rg') or {} --[[@as rg.settings.user]]
  local publicClient = rg_ls.create_server(settings)
  return publicClient(dispatchers)
end

return rg_ls
