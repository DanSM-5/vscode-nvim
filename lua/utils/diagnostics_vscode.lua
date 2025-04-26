---@module 'types.vscode'

-- TODO: Support namespaces in vscode

-- require('vscode').eval('return vscode.languages.getDiagnostics(vscode.window.activeTextEditor.document.uri)')

---@class VsCodeDiagnostic
---@field code string|number Code to display in diagnostics window
---@field message string Diagnostic message
---@field range [VsCodeRange, VsCodeRange] Range for the diagnostic [start, end]
---@field severity string|number Severity value
---@field source string Source of the diagnostic

---@class DiagnosticItem
---@field source string Source name of the diagnostic
---@field start_line integer Line to start the diagnostic
---@field end_line integer Line to end the diagnostic
---@field start_col integer Column number to start the diagnostic
---@field end_col integer Column number to end the diagnostic
---@field message string Message to display for the diagnostic
---@field code integer|string Error code that the diagnostic displays
---@field bufnr integer Id reference to the buffer which display the diagnostic
---@field severity 1|2|3|4 Severity level for the diagnostic
---@field namespace? integer Optional namespace for the diagnostic (only used for nvim)

---@class DiagnosticsAdapter<T>: { _diagnostics: T[] }
---@field append fun(diagnostic: DiagnosticItem) Append diagnostic to report
---@field report fun(bufnr: integer) Submit diagnostics to appropriate diagnostic provider
---@field valid_buffer fun(bufnr: integer): boolean Checks if buffer is valid for diagnostics

---@class DiagnosticsAdapterBuilder
---@field new fun(): DiagnosticsAdapter

local vscodeSeverityMap = {
  [0] = vim.diagnostic.severity.ERROR,
  [1] = vim.diagnostic.severity.WARN,
  [2] = vim.diagnostic.severity.INFO,
  [3] = vim.diagnostic.severity.HINT,
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Information = vim.diagnostic.severity.INFO,
  Hint = vim.diagnostic.severity.HINT,
  -- E = vim.diagnostic.severity.ERROR,
  -- W = vim.diagnostic.severity.WARN,
  -- I = vim.diagnostic.severity.INFO,
  -- N = vim.diagnostic.severity.HINT,
}
local error_query = vim.treesitter.query.parse('query', '[(ERROR)(MISSING)] @a')
local autocmd_group = vim.api.nvim_create_augroup('vscode.treesitter', { clear = true })
local namespace = vim.api.nvim_create_namespace('vscode.treesitter.diagnostics')

-- NOTE: vscode severity should come as a number but if pulling
-- the whole severity object, it will come as text 🫠
-- These functions should be able to handle either case, so make
-- sure all severity transformations are use them.

---Convert severity to vscode format
---@param severity '1'|'2'|'3'|'4'|1|2|3|4
---@return number Severity in vscode format
local toVscodeSeverity = function(severity)
  ---@type number
  local intval = type(severity) == 'number' and severity or (tonumber(severity) or 1)

  return intval - 1
end

---Convert severity from vscode format
---@param severity string|number
---@return number Severity in nvim format
local fromVscodeSeverity = function(severity)
  return vscodeSeverityMap[severity]
end

---Check if bufnr is remote
---@param bufnr integer
local is_remote = function(bufnr)
  local path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':p')
  local _, matches = path:gsub('vscode%-remote:', '')
  return matches > 0
end

---Get diagnostics from vscode
---@param bufnr? integer
---@return VsCodeDiagnostic[]
local get_buf_diagnostics = function(bufnr)
  local opts = { args = {} }

  opts.args.bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts.args.path = vim.fn.fnamemodify(vim.fn.bufname(opts.args.bufnr), ':p')
  local _, matches = opts.args.path:gsub('vscode%-remote:', '')
  opts.args.remote = matches > 0

  ---@type VsCodeDiagnostic[]
  local diagnostics = require('vscode').eval(
    [[
      const document = vscode.workspace.textDocuments.find(td => {
        const path = args.remote ? td.uri?._formatted : td.uri.fsPath
        return path === args.path;
      }) || vscode.window.activeTextEditor.document;

      return vscode.languages.getDiagnostics(document.uri);
  ]],
    opts
  )

  return diagnostics
end

---Get diagnostics from vscode transformed on neovim format
---@see vim.Diagnostic
---@param bufnr? integer Buffer to request diagnostics from
---@return vim.Diagnostic[]
local get_buf_diagnostics_as_nvim = function(bufnr)
  local diagnostics = get_buf_diagnostics(bufnr)

  ---@type vim.Diagnostic[]
  local nvim_diagnostics = {}

  for _, vsd in ipairs(diagnostics) do
    table.insert(nvim_diagnostics, {
      source = vsd.source,
      lnum = vsd.range[1].line,
      end_lnum = vsd.range[2].line,
      col = vsd.range[1].character,
      end_col = vsd.range[2].character,
      message = vsd.message,
      code = vsd.code,
      bufnr = bufnr or vim.api.nvim_get_current_buf(),
      namespace = namespace,
      severity = fromVscodeSeverity(vsd.severity),
    })
  end

  return nvim_diagnostics
end

---Set treesitter diagnostics in vscode
---@param diagnostics VsCodeDiagnostic[]
---@param bufnr number Buffer to apply diagnostics to
local vsc_set_diagnostics = function(diagnostics, bufnr)
  local path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':p')
  local _, matches = path:gsub('vscode%-remote:', '')
  local remote = matches > 0

  require('vscode').eval_async(
    [[
    const editor = vscode.window.activeTextEditor;
    const document = vscode.workspace.textDocuments.find(td => {
      const path = args.remote ? td.uri?._formatted : td.uri.fsPath
      return path === args.path;
    }) || editor.document;
    const pathId = document.uri.fsPath;

    const diagnostics = args.diagnostics.map(n => {
      const [start, end] = n.range
      const vd = new vscode.Diagnostic(
        new vscode.Range(
          new vscode.Position(start.line, start.character),
          new vscode.Position(end.line, end.character),
        ),
        n.message,
        vscode.DiagnosticSeverity[n.severity]
      );

      vd.source = n.source;
      vd.code = n.code;

      return vd;
    });

    let diagnosticCollection;
    if (globalThis.ts_diagnostics?.has(args.bufnr)) {
      diagnosticCollection = globalThis.ts_diagnostics.get(args.bufnr);
      diagnosticCollection.clear();
    } else {
      diagnosticCollection = vscode.languages.createDiagnosticCollection(pathId);
    }

    logger.info({
      bufnr: args.bufnr,
      path: args.path,
      uri: pathId,
      remote: args.remote,
    })

    diagnosticCollection.set(document.uri, diagnostics);
    globalThis.ts_diagnostics?.set(args.bufnr, diagnosticCollection)
  ]],
    {
      args = {
        diagnostics = diagnostics,
        bufnr = bufnr,
        path = path,
        remote = remote,
      },
    }
  )
end


---@type DiagnosticsAdapterBuilder
local DiagnosticsAdapterNvim = {
  new = function ()
    ---@type DiagnosticsAdapter<vim.Diagnostic>
    local adapter = {
      _diagnostics = {},
    }
    -- adapter._diagnostics = { function () end }
    adapter.append = function(item)
      --- @type vim.Diagnostic
      local diagnostic = {
        source = 'treesitter',
        lnum = item.start_line,
        end_lnum = item.end_line,
        col = item.start_col,
        end_col = item.end_col,
        message = item.message,
        code = item.code,
        bufnr = item.bufnr,
        namespace = item.namespace,
        severity = item.severity,
      }

      table.insert(adapter._diagnostics, diagnostic)
    end

    adapter.report = function (bufnr)
      -- Change accumulated diagnostics to a temporary variable
      -- and cleanup adapter content until this point.
      local diagnostics = adapter._diagnostics
      adapter._diagnostics = {}

      vim.diagnostic.set(namespace, bufnr, diagnostics)
    end

    adapter.valid_buffer = function (bufnr)
      -- don't diagnose strange stuff
      if vim.bo[bufnr].buftype ~= '' then
        return false
      end

      return true
    end

    return adapter
  end
}

---@type DiagnosticsAdapterBuilder
local DiagnosticsAdapterVscode = {
  new = function ()
    ---@type DiagnosticsAdapter<VsCodeDiagnostic>
    local adapter = {
      _diagnostics = {},
    }

    adapter.append = function(item)
      --- @type VsCodeDiagnostic
      local diagnostic = {
        source = item.source,
        range = {
          {
            line = item.start_line,
            character = item.start_col,
          },
          {
            line = item.end_line,
            character = item.end_col,
          },
        },
        message = item.message,
        code = item.code,
        bufnr = item.bufnr,
        namespace = item.namespace,
        severity = toVscodeSeverity(item.severity),
      }

      table.insert(adapter._diagnostics, diagnostic)
    end

    adapter.report = function (bufnr)
      -- Change accumulated diagnostics to a temporary variable
      -- and cleanup adapter content until this point.
      local diagnostics = adapter._diagnostics
      adapter._diagnostics = {}

      vsc_set_diagnostics(diagnostics, bufnr)
    end

    adapter.valid_buffer = function (bufnr)
      -- don't diagnose strange stuff
      if vim.bo[bufnr].buftype ~= 'acwrite' then
        return false
      end

      return true
    end

    return adapter
  end
}

local DiagnosticsAdapter = vim.g.vscode and DiagnosticsAdapterVscode or DiagnosticsAdapterNvim

---Ensure the global object to handle diagnostic collections is enabled
local initialize_vscode_diagnostics = function ()
  require('vscode').eval([[
    globalThis.ts_diagnostics = globalThis.ts_diagnostics ? globalThis.ts_diagnostics : new Map()
  ]])
end

---Clean all diagnostics and create a new global map
local reset_vscode_diagnostics = function()
  require('vscode').eval([[
    globalThis?.ts_diagnostics?.forEach?.(collection => {
      collection?.clear();
    });

    globalThis.ts_diagnostics = new Map()
  ]])
end

---Clear diagnostics on [bufnr]
---@param bufnr integer
local clear_buff_vscode = function (bufnr)
  require('vscode').eval(
    [[
    globalThis?.ts_diagnostics?.get(args.bufnr)?.clear();
  ]],
    { args = { bufnr = bufnr } }
  )
end

---Initialize treesitter diagnostics
local initialize = function()
  if vim.g.vscode then
    initialize_vscode_diagnostics()
  end
end

local reset = function ()
  if vim.g.vscode then
    reset_vscode_diagnostics()
  end
end

---Clear diagnostics on [bufnr]
---@param bufnr integer
local clear_buff = function(bufnr)
  if vim.g.vscode then
    clear_buff_vscode(bufnr)
  else
    vim.diagnostic.set(namespace, bufnr, {})
  end
end

-- local current_file = vscode.eval("return vscode.window.activeTextEditor.document.fileName")
-- local current_tab_is_pinned = vscode.eval("return vscode.window.tabGroups.activeTabGroup.activeTab.isPinned")
-- vscode.eval("await vscode.env.clipboard.writeText(args.text)", { args = { text = "some text" } })

-- import * as vscode from 'vscode';
-- require('vscode').eval([[
--   function activate(context) {
--     const diagnosticCollection = vscode.languages.createDiagnosticCollection('ts_diagnostics');

--     vscode.workspace.onDidChangeTextDocument((event) => {
--       if (event.document.languageId === 'bas') {
--         updateDiags(event.document, diagnosticCollection);
--       }
--     });

--     vscode.workspace.textDocuments.forEach((document) => {
--       if (document.languageId === 'bas') {
--         updateDiags(document, diagnosticCollection);
--       }
--     });
--   }

--   function updateDiags(document, collection) {
--     let diag1 = new vscode.Diagnostic(
--       new vscode.Range(
--         new vscode.Position(3, 8),
--         new vscode.Position(3, 9)
--       ),
--       'Repeated assignment of loop variables',
--       vscode.DiagnosticSeverity.Hint
--     );
--     diag1.source = 'basic-lint';
--     diag1.relatedInformation = [
--       new vscode.DiagnosticRelatedInformation(
--         new vscode.Location(document.uri, new vscode.Range(new vscode.Position(2, 4), new vscode.Position(2, 5))),
--         'First assignment'
--       )
--     ];
--     diag1.code = 102;

--     if (document && path.basename(document.uri.fsPath) === 'test.bas') {
--       collection.set(document.uri, [diag1]);
--     } else {
--       collection.clear();
--     }
--   }
-- ]])

---Add treesitter diagnostics to vscode using bufnr
---@param bufnr number
local diagnose_buffer = function(bufnr)
  if not vim.diagnostic.is_enabled({ bufnr = bufnr }) then
    return
  end

  local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })

  if not parser then
    return
  end

  ---@type DiagnosticsAdapter
  local diagnosticAdapter = DiagnosticsAdapter.new()

  if not diagnosticAdapter.valid_buffer(bufnr) then
    return
  end

  parser:parse(false, function(_, trees)
    if not trees then
      return
    end

    parser:for_each_tree(function(tree, ltree)
      -- only process trees containing errors
      if tree:root():has_error() then
        for _, node in error_query:iter_captures(tree:root(), bufnr) do
          local lnum, col, end_lnum, end_col = node:range()

          -- collapse nested syntax errors that occur at the exact same position
          local parent = node:parent()
          if parent and parent:type() == 'ERROR' and parent:range() == node:range() then
            goto continue
          end

          -- clamp large syntax error ranges to just the line to reduce noise
          if end_lnum > lnum then
            end_lnum = lnum + 1
            end_col = 0
          end

          local message = ''

          if node:missing() then
            message = string.format('missing `%s`', node:type())
          else
            message = 'error'
          end

          -- add context to the error using sibling and parent nodes
          local previous = node:prev_sibling()
          if previous and previous:type() ~= 'ERROR' then
            local previous_type = previous:named() and previous:type() or string.format('`%s`', previous:type())
            message = message .. ' after ' .. previous_type
          end

          if parent and parent:type() ~= 'ERROR' and (previous == nil or previous:type() ~= parent:type()) then
            message = message .. ' in ' .. parent:type()
          end

          diagnosticAdapter.append({
            source = 'treesitter',
            start_line = lnum,
            start_col = col,
            end_line = end_lnum,
            end_col = end_col,
            message = message,
            code = string.format('%s-syntax', ltree:lang()),
            bufnr = bufnr,
            severity = vim.diagnostic.severity.ERROR,
            namespace = namespace,
          })

          ::continue::
        end
      end
    end)
  end)

  diagnosticAdapter.report(bufnr)
end

--- @param args vim.api.keyset.create_autocmd.callback_args
local function diagnose(args)
  -- vim.print('Sending diagnostics to buf:' .. args.buf)
  diagnose_buffer(args.buf)
end

---Start treesitter diagnostics
---@param buf? number
local start_vscode = function(buf)
  vim.api.nvim_create_autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
    desc = '[TS] treesitter diagnostics',
    group = autocmd_group,
    callback = vim.schedule_wrap(diagnose),
  })
  if buf ~= nil and type(buf) == 'number' then
    diagnose_buffer(buf)
  end
end

---Stop treesitter diagnostics
---@param buf number
local stop_vscode = function(buf)
  autocmd_group = vim.api.nvim_create_augroup('editor.treesitter', { clear = true })
  clear_buff(buf)
end

---Start treesitter diagnostics
---@param buf? number
local start_nvim = function (buf)
  vim.api.nvim_create_autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
    desc = '[TS] treesitter diagnostics',
    group = autocmd_group,
    callback = vim.schedule_wrap(diagnose),
  })
  if buf ~= nil and type(buf) == 'number' then
    diagnose_buffer(buf)
  end
end

---Stop treesitter diagnostics
---@param buf number
local stop_nvim = function (buf)
  autocmd_group = vim.api.nvim_create_augroup('editor.treesitter', { clear = true })
  vim.diagnostic.set(namespace, buf, {})
end

---Start treesitter diagnostics
---@param buf? number
local start_ts_diagnostics = vim.g.vscode and start_vscode or start_nvim

---Stop treesitter diagnostics
---@param buf number
local stop_ts_diagnostics = vim.g.vscode and stop_vscode or stop_nvim

---Set diagnostics from vscode into vim.diagnostics
---@param bufnr? integer
local set_nvim_diagnostics_from_vscode = function(bufnr)
  local buf = bufnr or vim.api.nvim_get_current_buf()
  local diagnostics = get_buf_diagnostics_as_nvim(buf)
  vim.diagnostic.set(namespace, buf, diagnostics)
end

-- Ensure it is initialized when loading the module
initialize()

return {
  toVscodeSeverity = toVscodeSeverity,
  fromVscodeSeverity = fromVscodeSeverity,
  vsc_set_diagnostics = vsc_set_diagnostics,
  get_buf_diagnostics = get_buf_diagnostics,
  initialize = initialize,
  reset = reset,
  get_buf_diagnostics_as_nvim = get_buf_diagnostics_as_nvim,
  diagnose_buffer = diagnose_buffer,
  start_ts_diagnostics = start_ts_diagnostics,
  stop_ts_diagnostics = stop_ts_diagnostics,
  clear_buff = clear_buff,
  diagnose = diagnose,
  set_nvim_diagnostics_from_vscode = set_nvim_diagnostics_from_vscode,
  is_remote = is_remote,
}
