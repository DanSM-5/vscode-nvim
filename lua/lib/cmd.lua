---Get the matching value from the a list
---@param options string[]
---@param value string
---@return string[]
local function get_matched(options, value)
  local matched = vim.tbl_filter(function(option)
    local _, matches = string.gsub(option, value, '')
    return matches > 0
  end, options)

  return #matched > 0 and matched or options
end

return {
  get_matched = get_matched,
}
