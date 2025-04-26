local templates = {
  google = 'https://google.com/search?q=%s',
  bing = 'https://www.bing.com/search?q=%s',
  duckduckgo = 'https://duckduckgo.com/?q=%s',
  wikipedia = 'https://en.wikipedia.org/w/index.php?search=%s',
  brave = 'https://search.brave.com/search?q=%s',
  yandex = 'https://yandex.com/search/?text=%s',
  github = 'https://github.com/search?type=repositories&q=%s'
}

local default_engine = 'brave'

---Get the url template for search in a given engine
---@param engine? string Engine to get the template for
---@return string Template url for the search
local get_url = function (engine)
  engine = engine or default_engine
  return templates[engine]
end

---Checks if the string resembles a url
---@param input string
---@return boolean If the string does resembles a url
local function looks_like_url(input)
  local pat = "[%w%.%-_]+%.[%w%.%-_/]+"
  return input:match(pat) ~= nil
end

---Check if engine is valid
---@param engine? string
---@return boolean if the given engine is valid
local function is_valid_engine(engine)
  return templates[engine] ~= nil
end

---Search a string in the given engine
---if query resembles a url, it will be opened as is
---@param query string a string to search
---@param engine? string engine to use for search
local function search_browser(query, engine)
  local q = query

  if not looks_like_url(query) then
    local format = get_url(engine)
    q = format:format(vim.uri_encode(q))
  end

  vim.ui.open(q)
end

return {
  looks_like_url = looks_like_url,
  search_browser = search_browser,
  is_valid_engine = is_valid_engine,
}
