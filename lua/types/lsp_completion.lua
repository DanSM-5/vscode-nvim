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
---@field max_item_count? integer


---@class AbstractContextOptionsRg
---@field public debug? boolean enable debug logs
---@field public debounce? integer ms to debounce requests
---@field public cwd? string directory to use when executing jobs
---@field public pattern? string pattern to for completions
---@field public additional_arguments? string extra arguments for commands
---@field public context_before? integer how much context to show before
---@field public context_after? integer how much context to show after
---@field public keyword_length? integer minimum length of the word to start a search

---@class AbstractContextRg: AbstractContext
---@field option? AbstractContextOptionsRg
