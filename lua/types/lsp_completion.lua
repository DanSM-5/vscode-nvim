---@alias cmp.ContextReason 'auto' | 'manual' | 'triggerOnly' | 'none'

---@class cmp.Cache
---@field public entries any

---@class cmp.ContextOption
---@field public reason cmp.ContextReason|nil

---@class cmp.Context
---@field public id integer
---@field public cache cmp.Cache
---@field public prev_context cmp.Context
---@field public option cmp.ContextOption
---@field public filetype string
---@field public time integer
---@field public bufnr integer
---@field public cursor vim.Position|lsp.Position
---@field public cursor_line string
---@field public cursor_after_line string
---@field public cursor_before_line string
---@field public aborted boolean
---@field public before_char string custom

---@class LspRpcContext
---@field public triggerCharacter string
---@field public triggerKind integer

---@class LspRpcPosition
---@field public character integer
---@field public line integer

---@class LspRpcTextDocument
---@field public uri string

---@class LspRpcRequest
---@field public context LspRpcContext
---@field public position LspRpcPosition
---@field public textDocument LspRpcTextDocument

---@class AbstractContext
---@field context cmp.Context
---@field offset integer
---@field completion_context { triggerKind: integer }
