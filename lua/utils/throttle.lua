---@module 'lib.async'

---@generic F: fun()
---@param ms number
---@param fn F
---@return F
local function throttle(ms, fn)
  ---@type LibAsync
  local async
  local pending = false

  return function()
    if async and async:running() then
      pending = true
      return
    end
    ---@async
    async = require('lib.async').new(function()
      repeat
        pending = false
        fn()
        async:sleep(ms)
      until not pending
    end)
  end
end

return {
  throttle = throttle,
}
