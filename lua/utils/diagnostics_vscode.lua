
-- require('vscode').eval('return vscode.languages.getDiagnostics(vscode.window.activeTextEditor.document.uri)')

---@class VsCodeRange
---@field character number Column number. 0 based indexed.
---@field line number Line number. 0 based indexed.

---@class VsCodeDiagnostic
---@field code string|number Code to display in diagnostics window
---@field message string Diagnostic message
---@field range [VsCodeRange, VsCodeRange] Range for the diagnostic [start, end]
---@field severity string|number Severity value
---@field source string Source of the diagnostic

---@class NvimTsDiagnostic
---@field code string|number Code to display in diagnostics window
---@field message string Diagnostic message
---@field start [number, number] Start range for the diagnostic [line, col]
---@field end [number, number] End range for the diagnostic [line, col]
---@field severity string|number Severity value
---@field source string Source of the diagnostic

local vscodeSeverityMap = {
  [0] = vim.diagnostic.severity.ERROR,
  [1] = vim.diagnostic.severity.WARN,
  [2] = vim.diagnostic.severity.INFO,
  [3] = vim.diagnostic.severity.HINT,
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Information = vim.diagnostic.severity.INFO,
  Hint = vim.diagnostic.severity.HINT,
}
local error_query = vim.treesitter.query.parse('query', '[(ERROR)(MISSING)] @a')
local autocmd_group = vim.api.nvim_create_augroup('vscode.treesitter', { clear = true })
local namespace = vim.api.nvim_create_namespace('vscode.treesitter.diagnostics')

---Ensure the global object to handle diagnostic collections is enabled
local initialize = function ()
  require('vscode').eval([[
    globalThis.ts_diagnostics = globalThis.ts_diagnostics ? globalThis.ts_diagnostics : new Map()
  ]])
end

---Clean all diagnostics and create a new global map
local reset = function ()
  require('vscode').eval([[
    globalThis?.ts_diagnostics?.forEach?.(collection => {
      collection?.clear();
    });

    globalThis.ts_diagnostics = new Map()
  ]])
end

---Clear diagnostics on [bufnr]
---@param bufnr integer
local clear_buff = function (bufnr)
  require('vscode').eval([[
    globalThis?.ts_diagnostics?.get(args.bufnr)?.clear();
  ]], { args = { bufnr = bufnr } })
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

-- NOTE: vscode severity should come as a number but if pulling
-- the whole severity object, it will come as text 🫠
-- These functions should be able to handle either case, so make
-- sure all severity transformations are use them.

---Convert severity to vscode format
---@param severity string|number
local toVscodeSeverity = function (severity)
  return vscodeSeverityMap[severity] - 1
end

---Convert severity from vscode format
---@param severity string|number
local fromVscodeSeverity = function (severity)
  return vscodeSeverityMap[severity]
end

---Get diagnostics from vscode
---@param bufnr? integer
---@return VsCodeDiagnostic[]
local get_buf_diagnostics = function (bufnr)
  local opts = {}

  if bufnr ~= nil then
    opts.bufnr = bufnr
    opts.path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':p')
  end

  ---@type VsCodeDiagnostic[]
  local diagnostics = require('vscode').eval([[
    if (opts.bufnr && opts.bufnr !== 0) {
      const document = vscode.workspace.textDocuments.find(td => {
        return td.uri.fsPath === args.path;
      });

      return vscode.languages.getDiagnostics(
        document?.uri || vscode.window.activeTextEditor.document.uri
      );
    }

    return vscode.languages.getDiagnostics(
      vscode.window.activeTextEditor.document.uri
    )
  ]], opts)

  return diagnostics
end

---Get diagnostics from vscode transformed on neovim format
---@see vim.Diagnostic
---@param bufnr? integer Buffer to request diagnostics from
---@return vim.Diagnostic[]
local get_buf_diagnostics_as_nvim = function (bufnr)
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
      severity = fromVscodeSeverity(vsd.severity)
    })
  end

  return nvim_diagnostics
end


---Set treesitter diagnostics in vscode
---@param diagnostics NvimTsDiagnostic[]
---@param bufnr number Buffer to apply diagnostics to
local vsc_set_diagnostics = function (diagnostics, bufnr)
  local path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':p')
  require('vscode').eval_async([[
    const editor = vscode.window.activeTextEditor;
    const document = vscode.workspace.textDocuments.find(td => {
      return td.uri.fsPath === args.path;
    }) || editor.document;
    const pathId = document.uri.fsPath;

    const diagnostics = args.diagnostics.map(n => {
      const vd = new vscode.Diagnostic(
        new vscode.Range(
          new vscode.Position(n.start[0], n.start[1]),
          new vscode.Position(n.end[0], n.end[1]),
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
    })

    diagnosticCollection.set(document.uri, diagnostics);
    globalThis.ts_diagnostics?.set(args.bufnr, diagnosticCollection)
  ]], { args = { diagnostics = diagnostics, bufnr = bufnr, path = path } })
end

---Add treesitter diagnostics to vscode using bufnr
---@param bufnr number
local diagnose_buffer = function (bufnr)
  if not vim.diagnostic.is_enabled({bufnr = bufnr}) then
    return
  end

  -- don't diagnose strange stuff
  -- if vim.bo[bufnr].buftype ~= '' then
  --   return
  -- end

  local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })

  if not parser then
    return
  end

  ---@type NvimTsDiagnostic[]
  local diagnostics = {}

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

          --- @type NvimTsDiagnostic
          local diagnostic = {
            source = 'treesitter',
            start = { lnum, col },
            ['end'] = { end_lnum, end_col },
            message = '',
            code = string.format('%s-syntax', ltree:lang()),
            bufnr = bufnr,
            severity = toVscodeSeverity(vim.diagnostic.severity.ERROR)
          }
          if node:missing() then
            diagnostic.message = string.format('missing `%s`', node:type())
          else
            diagnostic.message = 'error'
          end

          -- add context to the error using sibling and parent nodes
          local previous = node:prev_sibling()
          if previous and previous:type() ~= 'ERROR' then
            local previous_type = previous:named() and previous:type() or string.format('`%s`', previous:type())
            diagnostic.message = diagnostic.message .. ' after ' .. previous_type
          end

          if parent and parent:type() ~= 'ERROR' and (previous == nil or previous:type() ~= parent:type()) then
            diagnostic.message = diagnostic.message .. ' in ' .. parent:type()
          end

          table.insert(diagnostics, diagnostic)
          ::continue::
        end
      end
    end)
  end)

  vsc_set_diagnostics(diagnostics, bufnr)
end

--- @param args vim.api.keyset.create_autocmd.callback_args
local function diagnose(args)
  if vim.fn.filereadable(vim.fn.bufname(args.buf)) == 0 then
    return
  end

  vim.print('Sending diagnostics to buf:' .. args.buf)
  diagnose_buffer(args.buf)
end

---Start treesitter diagnostics
---@param buf? number
local start_ts_diagnostics = function (buf)
  initialize()
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
local stop_ts_diagnostics = function (buf)
  autocmd_group = vim.api.nvim_create_augroup('editor.treesitter', { clear = true })
  clear_buff(buf)
end

---Set diagnostics from vscode into vim.diagnostics
---@param bufnr? integer
local set_nvim_diagnostics_from_vscode = function (bufnr)
  local buf = bufnr or vim.api.nvim_get_current_buf()
  local diagnostics = get_buf_diagnostics_as_nvim(buf)
  vim.diagnostic.set(namespace, buf, diagnostics)
end

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
  set_nvim_diagnostics_from_vscode = set_nvim_diagnostics_from_vscode,
}
