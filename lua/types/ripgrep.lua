---@class rg.Message
---@field public type 'begin'|'match'|'context'|'end'
---@field public data rg.MessageData

---@class rg.MessageData
---@field public path       rg.MessageDataPath
---@field public lines      rg.MessageDataLines|nil
---@field public submatches rg.MessageSubmatch[]|nil

---@class rg.MessageDataPath
---@field public text string

---@class rg.MessageDataLines
---@field public text string

---@class rg.MessageSubmatch
---@field public match rg.MessageSubmatchMatch

---@class rg.MessageSubmatchMatch
---@field public text string|nil

---@alias rg.CallbackFn fun(opt: { items: table, isIncomplete: boolean })

---@class rg.Source
---@field public running_job_id number
---@field public json_decode fun(s: string): rg.Message
---@field public timer any
---@field public new fun(): rg.Source
---@field public complete fun(self: rg.Source, request: AbstractContextRg, callback: rg.CallbackFn)
---@field public display_name? string
---@field public get_keyword_pattern function
---@field public is_available? function
---@field public match_keyword_pattern function
---@field public name? string
