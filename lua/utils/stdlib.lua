-- Collection of utility functions
-- There must not be imports on the top level of this script

-- luajit windows detection
-- local is_win = jit.os:find('Windows')

---Concatenates 2 arrays
---@generic T
---@param t1 T[]
---@param t2 T[]
---@return T[]
local function array_concat(t1, t2)
  local result = {}
  for _, v in ipairs(t1) do table.insert(result, v) end
  for _, v in ipairs(t2) do table.insert(result, v) end
  return result
end

---Split the string into a list using the separator as delimiter
---@param inputstr string String to split
---@param sep string Character or group of characters to use for separator
---@return string[] List of strings after split
local function split(inputstr, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    table.insert(t, str)
  end
  return t
end

---Shallow copy a table
---@generic T Type of the table to shallow clone
---@param t T Table to shallow clone
---@return T New table with same keys and values from the original
local function shallow_clone(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

---Create a printable string from an argument
---@generic T
---@param o T
---@return string
local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

---@generic T
---@param list T[]
---@param add T[]
---@return T[]
local function extend(list, add)
  local idx = {}
  for _, v in ipairs(list) do
    idx[v] = v
  end
  for _, a in ipairs(add) do
    if not idx[a] then
      table.insert(list, a)
    end
  end
  return list
end

local function can_merge(v)
  return type(v) == 'table' and (vim.tbl_isempty(v) or not M.is_list(v))
end

--- Merges the values similar to vim.tbl_deep_extend with the **force** behavior,
--- but the values can be any type, in which case they override the values on the left.
--- Values will me merged in-place in the first left-most table. If you want the result to be in
--- a new table, then simply pass an empty table as the first argument `vim.merge({}, ...)`
--- Supports clearing values by setting a key to `vim.NIL`
---@generic T
---@param ... T
---@return T
local function merge(...)
  local ret = select(1, ...)
  if ret == vim.NIL then
    ret = nil
  end
  for i = 2, select('#', ...) do
    local value = select(i, ...)
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = merge(ret[k], v)
      end
    elseif value == vim.NIL then
      ret = nil
    elseif value ~= nil then
      ret = value
    end
  end
  return ret
end

---Find the root directory or a given file
---@param lookFor string Name of the file to look for
---@return string|nil Path of the file name provided
local function find_root(lookFor)
  local path_to_file = vim.fs.find(lookFor, {
    path = vim.fn.expand('%:p:h'),
    upward = true,
  })[1]

  local root_dir = vim.fs.dirname(path_to_file)

  return root_dir
end

-- Try to gess root dir
---Tries to guess the root directory of a file
---and returns nil if nothing is found
---@param marker string|nil Name used to identify the rook of a project. If nil `.git` is used.
---@param initial string|nil Initial path to use as the base of the search. If nil, use current buffer path.
---@return string|nil path string when found or nil
local find_root_dir = function (marker, initial)
  local project_base_identifier = marker or '.git'
  local path = initial and vim.fn.fnamemodify(initial, ':p:h') or vim.fn.expand('%:p:h')
  return vim.fs.dirname(vim.fs.find(project_base_identifier, {
    path = path,
    upward = true,
  })[1])
end

-- Try to gess root dir
---Tries to guess the root directory of a project
---or defaults to current buffer directory
---@param marker string|nil Name used to identify the rook of a project. If nil `.git` is used.
---@param initial string|nil Initial path to use as the base of the search. If nil, use current buffer path.
---@return string path It should always return a string
local get_root_dir = function (marker, initial)
  local found = find_root_dir(marker, initial)
  return found and found or (initial or vim.fn.expand('%:p:h'))
end

--- Creates a weak reference to an object.
--- Calling the returned function will return the object if it has not been garbage collected.
---@generic T: table
---@param obj T
---@return T|fun():T?
local function weak(obj)
  local weak_ref = { _obj = obj }
  ---@return table<any, any>
  local function get()
    local ret = rawget(weak_ref, '_obj')
    return ret == nil and error('Object has been garbage collected', 2) or ret
  end
  local mt = {
    __mode = 'v',
    __call = function(t)
      return rawget(t, '_obj')
    end,
    __index = function(_, k)
      return get()[k]
    end,
    __newindex = function(_, k, v)
      get()[k] = v
    end,
    __pairs = function()
      return pairs(get())
    end,
  }
  return setmetatable(weak_ref, mt)
end

---Detect if file exists
---@param file string Path to file
---@return boolean Whether the path exist or not
local function file_exists(file)
  return (vim.uv or vim.loop).fs_stat(file) ~= nil
end

---Attempt to open a uri
---@param opts? { system?: boolean }
local function open(uri, opts)
  opts = opts or {}
  if not opts.system and file_exists(uri) then
    return require('utils.nvim').float({ style = '', file = uri })
  end
  local Config = require('lazy.core.config')
  local cmd
  if not opts.system and Config.options.ui.browser then
    cmd = { Config.options.ui.browser, uri }
  elseif vim.fn.has('win32') == 1 then
    cmd = { 'explorer', uri }
  elseif vim.fn.has('macunix') == 1 then
    cmd = { 'open', uri }
  else
    if vim.fn.executable('xdg-open') == 1 then
      cmd = { 'xdg-open', uri }
    elseif vim.fn.executable('wslview') == 1 then
      cmd = { 'wslview', uri }
    else
      cmd = { 'open', uri }
    end
  end

  local ret = vim.fn.jobstart(cmd, { detach = true })
  if ret <= 0 then
    local msg = {
      'Failed to open uri',
      ret,
      vim.inspect(cmd),
    }
    vim.notify(table.concat(msg, '\n'), vim.log.levels.ERROR)
  end
end

local function read_file(file)
  local fd = assert(io.open(file, 'r'))
  ---@type string
  local data = fd:read('*a')
  fd:close()
  return data
end

---Add contents to file
---@param file string Path to file to write
---@param contents string Contents to write
local function write_file(file, contents)
  local fd = assert(io.open(file, 'w+'))
  fd:write(contents)
  fd:close()
end

---@generic F: fun()
---@param ms number
---@param fn F
---@return F
local function throttle(ms, fn)
  ---@type Async
  local async
  local pending = false

  return function()
    if async and async:running() then
      pending = true
      return
    end
    ---@async
    async = require('utils.async').new(function()
      repeat
        pending = false
        fn()
        async:sleep(ms)

      until not pending
    end)
  end
end

-- Fast implementation to check if a table is a list
---@param t table
local function is_list(t)
  local i = 0
  ---@diagnostic disable-next-line: no-unknown
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

---@generic T
---@param list T[]
---@param fn fun(value: T, index?: integer, tbl?: T[]): boolean?
---@return T[]
local function filter(list, fn)
  ---@type `T`
  local ret = {}
  ---@type integer, `T`
  for _, v in ipairs(list) do
    if fn(v) then
      table.insert(ret, v)
    end
  end
  return ret
end

---@generic T
---@param list T[]
---@param fn fun(v: T):boolean?
---@return T|nil
local function find(fn, list)
  for _, v in ipairs(list) do
    if fn(v) then
      return v
    end
  end
  return nil
end

---@generic T
---@param list T[]
---@param fn fun(v: T):boolean?
---@return boolean
local function any(fn, list)
  for _, v in ipairs(list) do
    if fn(v) then
      return true
    end
  end
  return false
end

---@generic T
---@param list T[]
---@param fn fun(v: T):boolean?
---@return boolean
local function every(fn, list)
  for _, v in ipairs(list) do
    if not fn(v) then
      return false
    end
  end

  return true
end

---Execute a delegate function for each element in a table
---@generic V
---@param t table<string|integer, V>
---@param fn fun(value: V, key: string|integer, tbl?: table<string|integer>, V)
---@param opts? { case_sensitive?: boolean; pairs?: boolean }
local function foreach(t, fn, opts)
  opts = opts or {}

  ---@type string[]
  local keys = vim.tbl_keys(t)
  pcall(table.sort, keys, function(a, b)
    if opts.case_sensitive then
      return a < b
    end
    return a:lower() < b:lower()
  end)

  local mapper = opts.pairs and pairs or ipairs

  for _, key in mapper(keys) do
    fn(t[key], key, t)
  end
end

---Executes a mapping function to all elements of a numeric table
---@generic V, T
---@param list V[]
---@param fn fun(value: V, index?: integer, tbl?: V[]): T
---@return T[] Returns the mapped table
local function map(list, fn)
  ---@type `T`[]
  local out_table = {}

  ---@type integer, `V`
  for index, value in ipairs(list) do
    table.insert(out_table, fn(value, index, list))
  end

  return out_table
end

---Get a Collection of key-value pairs from a table
---@generic K, V
---@param tbl table<K, V>
---@return [K, V][] 
local function entries(tbl)
  ---@type [`K`, `V`][]
  local out_table = {}

  ---@type integer, `V`
  for key, value in pairs(tbl) do
    table.insert(out_table, { key, value })
  end

  return out_table
end


---Get a Collection of key-value pairs from a table
---@generic K
---@param tbl table<K, unknown>
---@return K[] 
local function keys(tbl)
  ---@type `K`[]
  local out_table = {}

  ---@type `K`
  for key, _ in pairs(tbl) do
    table.insert(out_table, key)
  end

  return out_table
end

---Get a Collection of key-value pairs from a table
---@generic V
---@param tbl table<unknown, V>
---@return V[] 
local function values(tbl)
  ---@type `V`[]
  local out_table = {}

  ---@type integer, `V`
  for _, value in pairs(tbl) do
    table.insert(out_table, value)
  end

  return out_table
end

---@param t table
---@param key string|string[]
---@return any
local function key_get(t, key)
  local path = type(key) == 'table' and key or split(key --[[@as string]], '.')
  local value = t
  for _, k in ipairs(path) do
    if type(value) ~= 'table' then
      return value
    end
    value = value[k]
  end
  return value
end

---@param t table
---@param key string|string[]
---@param value any
local function key_set(t, key, value)
  local path = type(key) == 'table' and key or split(key --[[@as string]], '.')
  local last = t
  for i = 1, #path - 1 do
    local k = path[i]
    if type(last[k]) ~= 'table' then
      last[k] = {}
    end
    last = last[k]
  end
  last[path[#path]] = value
end

--- Transform char to hex
--- @param c string|integer Characted value
--- @return string Hexadecimal representation of character
local char_to_hex = function(c)
  return string.format("%02X", string.byte(c))
end

--- Transform char to hex prefixed with %
--- @param c string|integer Characted value
--- @return string Hexadecimal representation of character prefixed with %
local encode_char_uri = function(c)
  return '%'..char_to_hex(c)
end

---Encode function for URIs
--- @see vim.uri_encode
---@param url string String to encode
---@param opts? { encode_spaces: boolean } Options for encoding
local function encodeURI(url, opts)
  if url == nil then
    return
  end
  opts = opts or { encode_spaces = false }
  url = url:gsub("\n", "\r\n")
  -- For more conservative enconding that encodes "_", "-", ".", "~"
  -- url = url:gsub("([^%w ])", char_to_hex)
  -- To be closer to RFC 3986, section 2.3: https://tools.ietf.org/html/rfc3986#section-2.3
  url = url:gsub("([^%w _%%%-%.~])", encode_char_uri)
  if opts.encode_spaces then
    url = url:gsub(" ", encode_char_uri)
  else
    url = url:gsub(" ", "+")
  end
  return url
end

---Convert hexadecimal representation into a char
---@param x string
---@return string
local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

---Decode function for URIs
---@see vim.uri_decode
---@param url string Decoded string
---@return string|nil decoded uri
local decodeURI = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

---Create a finally function block
---@generic T
---@param block T Function to execute. Returns nil if an error happens
---@param on_end fun(ok: boolean, ret: any[]) Function to call on end. It will have access to any error or return from the block function
---@return T Wrapped function with finally
---@example
---```lua
---local fetch_with_finally = create_finally(fetch, function(ok, ...)
---  print(ok and 'Completed' or 'Error')
---end)
---local data_or_nil = copy_with_finally()
---```
local function create_finally(block, on_end)
  local function _finally(ok, ...)
    on_end(ok, ...)

    if ok then
      return ...
    end
  end

  return function (...)
    return _finally(pcall(block, ...))
  end
end

---Finally function block
---Ref: https://github.com/siffiejoe/lua-finally
---@generic T
---@param block fun(...):T Function to execute.
---@param on_end fun(err: table|nil) Function to call on end. It will have an error if occurs.
---@return T Return from the block function if completes successfully
local function finally(block, on_end)
  local function _finally(ok, ...)
    if ok then
      on_end()
      return ...
    else
      on_end( (...) )
      error( (...), 0 )
    end
  end

  return _finally(pcall( block ))
end


---@generic T
---@param t T[] Table to check
---@param value T|fun(v: T): boolean Value to compare or predicate function reference
---@return boolean `true` if `t` contains `value`
local function contains(t, value)

             --- @generic T
  local pred --- @type fun(v: T): boolean
  if type(value) == 'function' then
    pred = value
  else
    ---@generic T
    ---@param v T
    ---@return boolean
    pred = function(v)
      return v == value
    end
  end

  for _, v in pairs(t) do
    if pred(v) then
      return true
    end
  end

  return false
end

---Creates an object (table :v) that allows to create
---arbitrary properties
---@example
---```lua
---local t = get_dynamic_object()
---t.foo = 'something'
---t.bar.baz.bad = 'foo'
-----[[ Output:
---{
---  bar = {
---    baz = {
---      bad = 'foo',
---      <metatable> = <1>{
---        __index = <function 1>,
---        self = <table 1>
---      }
---    }
---  },
---  foo = 'something',
---  <metatable> = <table 1>
---}
---]]
---```
---@return table<string, any>
local get_dynamic_object = function ()
  local meta = {}
  function meta.__index(t, k)
    if rawget(t, k) == nil then
      t[k] = setmetatable({}, meta.self)
    end

    return rawget(t, k)
  end
  meta.self = meta

  return meta
end

---Check if a given directory is a git directory
---@param dir string The initial directory
---@return boolean git_repo
local is_git_dir = function (dir)
  local found = find_root_dir('.git', dir)
  return found ~= nil
end

return {
  find_root = find_root,
  get_root_dir = get_root_dir,
  find_root_dir = find_root_dir,
  is_git_dir = is_git_dir,
  concat = array_concat,
  split = split,
  shallow_clone = shallow_clone,
  extend = extend,
  merge = merge,
  foreach = foreach,
  filter = filter,
  map = map,
  entries = entries,
  keys = keys,
  values = values,
  contains = contains,
  find = find,
  every = every,
  any = any,
  weak = weak,
  file_exists = file_exists,
  open = open,
  read_file = read_file,
  write_file = write_file,
  is_list = is_list,
  key_set = key_set,
  key_get = key_get,
  throttle = throttle,
  dump = dump,
  decodeURI = decodeURI,
  encodeURI = encodeURI,
  hex_to_char = hex_to_char,
  char_to_hex = char_to_hex,
  create_finally = create_finally,
  finally = finally,
  get_dynamic_object = get_dynamic_object,
}
