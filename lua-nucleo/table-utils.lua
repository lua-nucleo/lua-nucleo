--------------------------------------------------------------------------------
--- Small table utilities
-- @module lua-nucleo.table-utils
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local setmetatable, error, pairs, ipairs, tostring, select, type, assert,
      unpack
    = setmetatable, error, pairs, ipairs, tostring, select, type, assert,
      unpack or table.unpack

local rawget = rawget

local table_insert, table_remove = table.insert, table.remove

local math_min, math_max = math.min, math.max

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local is_number,
      is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_number',
        'is_table'
      }

local assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table'
      }

--------------------------------------------------------------------------------

--- Warning: it is possible to corrupt this with rawset and debug.setmetatable.
local empty_table = setmetatable(
    { },
    {
      __newindex = function(t, k, v)
        error("attempted to change the empty table", 2)
      end;

      __metatable = "empty_table";
    }
  )

--- @param t
-- @param s
-- @param ...
local function toverride_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      t[k] = v
    end
    -- Recursion is usually faster than calling select()
    return toverride_many(t, ...)
  end

  return t
end

--- @param t
-- @param s
-- @param ...
local function tappend_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      if t[k] == nil then
        t[k] = v
      else
        error("attempted to override table key `" .. tostring(k) .. "'", 2)
      end
    end

    -- Recursion is usually faster than calling select()
    return tappend_many(t, ...)
  end

  return t
end

--- @param t
-- @param s
-- @param ...
local function tijoin_many(t, s, ...)
  if s then
    -- Note: can't use ipairs() since we want to support tijoin_many(t, t)
    for i = 1, #s do
      t[#t + 1] = s[i]
    end

    -- Recursion is usually faster than calling select()
    return tijoin_many(t, ...)
  end

  return t
end

--- Keys are ordered in undetermined order
-- @param t
local tkeys = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = k
  end

  return r
end

--- Values are ordered in undetermined order
-- @param t
local tvalues = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = v
  end

  return r
end

--- Keys and values are ordered in undetermined order
-- @param t
local tkeysvalues = function(t)
  local keys, values = { }, { }

  for k, v in pairs(t) do
    keys[#keys + 1] = k
    values[#values + 1] = v
  end

  return keys, values
end

--- If table contains multiple keys with the same value,
-- only one key is stored in the result, picked in undetermined way.
-- @param t
local tflip = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = k
  end

  return r
end

--- If table contains multiple keys with the same value,
-- only one key is stored in the result, picked in undetermined way.
-- @param t
local tflip_inplace = function(t)
  for k, v in pairs(t) do
    t[v] = k
  end

  return t
end

--- If table contains multiple keys with the same value,
-- only the last such key (highest one) is stored in the result.
-- @param t
local tiflip = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = i
  end

  return r
end

--- @param t
local tset = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = true
  end

  return r
end

--- @param t
local tiset = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = true
  end

  return r
end

--- @param t
-- @param a
-- @param ...
local function tiinsert_args(t, a, ...)
  if a ~= nil then
    t[#t + 1] = a
    -- Recursion is usually faster than calling select() in a loop.
    return tiinsert_args(t, ...)
  end

  return t
end

--- @param fn
-- @param t
-- @param ...
local timap_inplace = function(fn, t, ...)
  for i = 1, #t do
    t[i] = fn(t[i], ...)
  end

  return t
end

--- @param fn
-- @param t
-- @param ...
local timap = function(fn, t, ...)
  local r = { }
  for i = 1, #t do
    r[i] = fn(t[i], ...)
  end
  return r
end

--- @param fn
-- @param t
-- @param ...
local timap_sliding = function(fn, t, ...)
  local r = {}

  for i = 1, #t do
    tiinsert_args(r, fn(t[i], ...))
  end

  return r
end

--- @param fn
-- @param t
-- @param ...
local tiwalk = function(fn, t, ...)
  for i = 1, #t do
    fn(t[i], ...)
  end
end

--- @param fn
local tiwalker = function(fn)
  return function(t)
    for i = 1, #t do
      fn(t[i])
    end
  end
end

--- @param fn
-- @param t
local twalk_pairs = function(fn, t)
  for k, v in pairs(t) do
    fn(k, v)
  end
end

local tequals = function(lhs, rhs)
  for k, v in pairs(lhs) do
    if v ~= rhs[k] then
      return false
    end
  end

  for k, v in pairs(rhs) do
    if lhs[k] == nil then
      return false
    end
  end

  return true
end

--- @param t
local tiunique = function(t)
  return tkeys(tiflip(t))
end

--- Deprecated, use tgenerate_1d_linear instead
-- @param n
-- @param generator
-- @param ...
local tgenerate_n = function(n, generator, ...)
  local r = { }
  for i = 1, n do
    r[i] = generator(...)
  end
  return r
end

--- @param n
-- @param fn
-- @param ...
local tgenerate_1d_linear = function(n, fn, ...)
  local r = { }
  for i = 1, n do
    r[#r + 1] = fn(i, ...)
  end
  return r
end

--- @param w
--- @param h
-- @param fn
-- @param ...
local tgenerate_2d_linear = function(w, h, fn, ...)
  local r = { }
  for y = 1, h do
    for x = 1, w do
      r[#r + 1] = fn(x, y, ...)
    end
  end
  return r
end

--- @param t
-- @param init
local taccumulate = function(t, init)
  local sum = init or 0
  for k, v in pairs(t) do
    sum = sum + v
  end
  return sum
end

local tnormalize, tnormalize_inplace
do
  local impl = function(t, r, sum)
    sum = sum or taccumulate(t)

    for k, v in pairs(t) do
      r[k] = v / sum
    end

    return r
  end

  --- @param t
  -- @param sum
  -- @local
  tnormalize = function(t, sum)
    return impl(t, { }, sum)
  end

  --- @param t
  -- @param sum
  -- @local
  tnormalize_inplace = function(t, sum)
    return impl(t, t, sum)
  end
end

local tclone
do
  local function impl(t, visited)
    local t_type = type(t)
    if t_type ~= "table" then
      return t
    end

    assert(not visited[t], "recursion detected")
    visited[t] = true

    local r = { }
    for k, v in pairs(t) do
      r[impl(k, visited)] = impl(v, visited)
    end

    visited[t] = nil

    return r
  end

  --- @param t
  -- @local
  tclone = function(t)
    return impl(t, { })
  end
end

--- Slow
-- @param t
-- @local
local tcount_elements = function(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

--- @param fn
-- @param t
local tremap_to_array = function(fn, t)
  local r = { }
  for k, v in pairs(t) do
    r[#r + 1] = fn(k, v)
  end
  return r
end

--- @param fn
-- @param t
-- @param ...
local tmap_values = function(fn, t, ...)
  local r = { }
  for k, v in pairs(t) do
    r[k] = fn(v, ...)
  end
  return r
end

--------------------------------------------------------------------------------

--- @param t
local torderedset = function(t)
  local r = { }

  for i = 1, #t do
    local v = t[i]

    -- Have to add this limitation to avoid size ambiquity.
    -- If you need ordered set of numbers, use separate storage
    -- for set and array parts (write make_ordered_set then).
    assert(type(v) ~= "number", "can't insert number into ordered set")

    r[v] = i
    r[i] = v
  end

  return r
end

--- @param t
-- @param v
-- @return[1] false if item already exists
-- @return[2] true otherwise
local torderedset_insert = function(t, v)
  -- See torderedset() for motivation
  assert(type(v) ~= "number", "can't insert number into ordered set")

  if not t[v] then
    local i = #t + 1
    t[v] = i
    t[i] = v

    return true
  end

  return false
end

--- Note this operation is really slow
-- @param t
-- @param v
-- @return[1] false if item didn't existed
-- @return[2] true otherwise
local torderedset_remove = function(t, v)
  -- See torderedset() for motivation
  assert(type(v) ~= "number", "can't remove number from ordered set")

  local pos = t[v]
  if pos then
    t[v] = nil
    -- TODO: Do table.remove manually then to do all in a single loop.
    table_remove(t, pos)
    for i = pos, #t do
      t[t[i]] = i -- Update changed numbers
    end
  end

  return false
end

--------------------------------------------------------------------------------

local twithdefaults
do
  --- Handles subtables (is "deep").
  -- Does not support recursive defaults tables
  -- WARNING: Uses tclone()! Do not use on tables with metatables!
  -- @param t
  -- @param defaults
  -- @local
  twithdefaults = function(t, defaults)
    for k, d in pairs(defaults) do
      local v = t[k]
      if v == nil then
        if type(d) == "table" then
          d = tclone(d)
        end
        t[k] = d
      elseif type(v) == "table" and type(d) == "table" then
        twithdefaults(v, d)
      end
    end

    return t
  end
end

--------------------------------------------------------------------------------

--- @param pred
-- @param t
-- @param ...
local tifilter = function(pred, t, ...)
  local r = { }
  for i = 1, #t do
    local v = t[i]
    if pred(v, ...) then
      r[#r + 1] = v
    end
  end
  return r
end

--------------------------------------------------------------------------------

--- @param value
-- @param t
local tsetof = function(value, t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = value
  end

  return r
end

--------------------------------------------------------------------------------

--- @param ...
local tset_many = function(...)
  local r = { }

  for i = 1, select("#", ...) do
    for k, v in pairs((select(i, ...))) do
      r[v] = true
    end
  end

  return r
end

-- TODO: Pick a better name?

--- @param t
local tidentityset = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = v
  end

  return r
end

--------------------------------------------------------------------------------

--- @param t
-- @param key
local timapofrecords = function(t, key)
  local r = { }

  for i = 1, #t do
    local v = t[i]
    r[assert(v[key], "missing record key field")] = v
  end

  return r
end

--- @param t
local tivalues = function(t)
  local r = { }

  for i = 1, #t do
    r[#r + 1] = t[i]
  end

  return r
end

--------------------------------------------------------------------------------

local treadonly, treadonly_ex
do
  local newindex = function()
    error("attempted to change read-only table")
  end

  --- NOTE: Optimized to be fast at simple value indexing.
  --       Slower on initialization and on table value fetching.
  -- WARNING: This does not protect userdata.
  -- @param value
  -- @param callbacks
  -- @param tostring_fn
  -- @param disable_nil
  -- @local
  treadonly = function(value, callbacks, tostring_fn, disable_nil)
    callbacks = callbacks or empty_table
    if disable_nil == nil then
      disable_nil = true
    end

    arguments(
        "table", value,
        "table", callbacks
      )

    optional_arguments(
        "function", tostring_fn,
        "boolean", disable_nil -- TODO: ?! Not exactly optional
      )

    local mt =
    {
      __metatable = "treadonly"; -- protect metatable

      __index = function(t, k)
        local v = rawget(value, k)
        if is_table(v) then
          -- TODO: Optimize
          v = treadonly(v, callbacks, tostring_fn, disable_nil)
        end
        if v == nil then -- TODO: Try to use metatables
          -- Note: __index does not support multiple return values in 5.1,
          --       so we can not do call right here.
          local fn = callbacks[k]
          if fn then
            return function(...) return fn(value, ...) end
          end
          if disable_nil then
            error(
                "attempted to read inexistant value at key " .. tostring(k),
                2
              )
          end
        end
        return v
      end;

      __newindex = newindex;
    }

    if tostring_fn then
      mt.__tostring = function() return tostring_fn(value) end
    end

    return setmetatable({ }, mt)
  end

  --- Changes to second return value are guaranteed to affect first one
  -- NOTE: Optimized to be fast at simple value indexing.
  --       Slower on initialization and on table value fetching.
  -- WARNING: This does not protect userdata.
  -- @param value
  -- @param callbacks
  -- @param tostring_fn
  -- @param disable_nil
  -- @local
  treadonly_ex = function(value, ...)
    local protected = treadonly(value, ...)
    return protected, value
  end
end

--- @param fn
-- @param t
local tmap_kv = function(fn, t)
  local r = { }
  for k, v in pairs(t) do
    k, v = fn(k, v)
    r[k] = v
  end
  return r
end

--- @param t
-- @param key_name
local tmapofrecordgroups = function(t, key_name)
  local r = { }
  for k, v in pairs(t) do
    local v = t[k]
    local key = assert(v[key_name], "missing required key")
    local g = r[key]
    if not g then
      g = { }
      r[key] = g
    end
    g[#g + 1] = v
  end

  return r
end

--- @param t
-- @param key_name
local timapofrecordgroups = function(t, key_name)
  local r = { }
  for i = 1, #t do
    local v = t[i]
    local key = assert(v[key_name], "missing required key")
    local g = r[key]
    if not g then
      g = { }
      r[key] = g
    end
    g[#g + 1] = v
  end

  return r
end

--- @param t
-- @param k
local tilistofrecordfields = function(t, k)
  local r = { }
  for i = 1, #t do
    local v = t[i][k]
    assert(v ~= nil, "missing required key")
    r[#r + 1] = v
  end
  return r
end

--- @param t
-- @param n
-- @param count
-- @param random
local tipermute_inplace = function(t, n, count, random)
  n = n or #t
  count = count or n
  random = random or math.random

  for i = 1, count do
    local j = random(i, n)
    t[i], t[j] = t[j], t[i]
  end

  return t
end

--- @param t
-- @param key_name
-- @param value_name
local tkvtorecordlist = function(t, key_name, value_name)
  local result = { }
  for k, v in pairs(t) do
    result[#result + 1] = { [key_name] = k, [value_name] = v }
  end
  return result
end

--- @param t
-- @param k
-- @param nextk
-- @param ...
local function tgetpath(t, k, nextk, ...)
  if k == nil then
    return nil
  end

  local v = t[k]
  if not is_table(v) or nextk == nil then
    return v
  end

  return tgetpath(v, nextk, ...)
end

--  tsetpath(tabl, "a", "b", "c", d)
--  tabl.a.b.c[d] = val
local tsetpath
do
  local function impl(nargs, dest, key, ...)

    if nargs == 0 then
      return dest
    end

    if key == nil then
      error("tsetpath: nil can't be a table key")
    end

    dest[key] = assert_is_table(
        dest[key] or { },
        "key `" .. tostring(key)
     .. "' already exists and its value is not a table"
      )

    return impl(nargs - 1, dest[key], ...)
  end

  --- @param dest
  -- @param ...
  -- @local
  tsetpath = function(dest, ...)
    local nargs = select("#", ...)
    if nargs == 0 then
      return dest
    end

    return impl(nargs, dest, ...)
  end
end

local tsetpathvalue
do
  local function impl(nargs, value, dest, key, ...)
    assert(nargs > 0)

    if key == nil then
      error("tsetpathvalue: nil can't be a table key")
    end

    if nargs == 1 then
      dest[key] = value
      return dest
    end

    dest[key] = assert_is_table(
        dest[key] or { },
        "key `" .. tostring(key)
     .. "' already exists and its value is not a table"
      )

    return impl(nargs - 1, value, dest[key], ...)
  end

  --- @param value
  -- @param dest
  -- @param ...
  -- @local
  tsetpathvalue = function(value, dest, ...)
    local nargs = select("#", ...)
    if nargs == 0 then
      return dest
    end

    return impl(nargs, value, dest, ...)
  end
end

-- TODO: rename to tislice

--- @param t
-- @param start_i
-- @param end_i
local tslice = function(t, start_i, end_i)
  local r = { }

  start_i = math_max(start_i, 1)
  end_i = math_min(end_i, #t)
  for i = start_i, end_i do
    r[i - start_i + 1] = t[i]
  end

  return r
end

--- @param t
-- @param ...
local tarraylisttohashlist = function(t, ...)
  local r = { }
  local nargs = select("#", ...)

  for i = 1, #t do
    local item = { }
    for j = 1, nargs do
      local hash = select(j, ...)
      if hash ~= nil then -- ignore nil from arguments
        item[hash] = t[i][j]
      end
    end
    r[#r + 1] = item
  end

  return r
end

--- @param t
-- @param ...
local tarraytohash = function(t, ...)
  local r = { }
  local nargs = select("#", ...)

  for i = 1, nargs do
    local hash = select(i, ...)
    if hash ~= nil then -- ignore nil from arguments
      r[hash] = t[i]
    end
  end

  return r
end

--- @param t
local tisempty = function(t)
  return next(t) == nil
end

--- @param t
-- @param v
local tifindvalue_nonrecursive = function(t, v)
  for i = 1, #t do
    if t[i] == v then
      return true
    end
  end
  return false
end

--- @param t
local tkvlist2kvpairs = function(t)
  local r = { }
  for i = 1, #t, 2 do
    local k, v = t[i], t[i+1]
    if k ~= nil then
      r[k] = v
    end
  end
  return r
end

--- @param t
-- @param f
-- @param strict
local tfilterkeylist = function(t, f, strict)
  strict = strict or false
  local r = { }

  for i = 1, #f do
    local k = f[i]
    if t[k] ~= nil then
      r[k] = t[k]
    elseif strict then
      return nil, "Field `" .. tostring(k) .. "' is absent"
    end
  end
  return r
end

--- @param fn
-- @param t
-- @param ...
local tkvmap_unpack = function(fn, t, ...)
  local r = { }
  for k, v in pairs(t) do
    k, v = fn(k, ...), fn(v, ...)

    if k ~= nil and v ~= nil then
      r[#r + 1] = k
      r[#r + 1] = v
    end
  end
  return unpack(r)
end

--- @param t
local tkvlist_to_hash = function(t)
  local r = { }
  for i = 1, #t, 2 do
    r[t[i]] = t[i + 1]
  end
  return r
end

--- @param ...
local tmerge_many = function(...)
  return toverride_many({ }, ...)
end

local TISARRAY_NOT_OBJ = 'tisarray.not'

--- Makes table to be treated as JSON object in tisarray()
-- @param t
local tisarray_not = function(t)
  if getmetatable(t) then 
    error('tisarray_not: tables with metatables are not supported') 
  end
  
  return setmetatable(t, { __metatable = TISARRAY_NOT_OBJ })
end

--- Note the empty table is treated as an array
-- @return[1] true if a table is an array
-- @return[2] false otherwise
-- @param t
local tisarray = function(t)
  if getmetatable(t) == TISARRAY_NOT_OBJ then 
    return false
  end
  for k, _ in pairs(t) do
    if
      -- Array keys should be numbers...
      not is_number(k)
      -- ...greater than 1...
      or k < 1
      -- ...in a continuous sequence...
      or (k > 1 and t[k - 1] == nil)
      -- ...of integers...
      or k % 1 ~= 0
      -- ...avoiding floating point overflow
      or k == k - 1
    then
      return false
    end
  end
  return true
end

--------------------------------------------------------------------------------

local tdeepfilter
do
  local function impl(predicate, t, visited)
    if not is_table(t) then
      return t
    end

    local r = { }

    assert(not visited[t], 'recursion detected')
    visited[t] = true

    for k, v in pairs(t) do
      if predicate(v, k, t) then
        r[impl(predicate, k, visited)] = impl(predicate, v, visited)
      end
    end

    visited[t] = nil

    return r
  end

  --- @param predicate
  -- @param t
  -- @local
  tdeepfilter = function(predicate, t)
    return impl(predicate, t, { })
  end
end

--------------------------------------------------------------------------------

local tifindallpermutations
do
  --- Finds all permutations of elements in the input linear array table `t`
  -- and puts them into the `results` table.
  -- @param t Input linear array table.
  -- @param results All found permutations will be placed here.
  -- @return None
  -- @local
  -- @usage
  -- local tifindallpermutations
  --       = import 'lua-nucleo/table-utils.lua'
  --       {
  --         'tifindallpermutations'
  --       }
  --
  -- local permutations0 = tifindallpermutations({ })
  -- -- permutations0 is { } here
  --
  -- local permutations1 = tifindallpermutations({ 1 }, { { 1 } })
  -- -- permutations1 is { { 1 } } here
  --
  -- local permutations2 = tifindallpermutations({ 1, 2 })
  -- -- permutations2 is { { 1, 2 }, { 2, 1 } }
  --
  -- local permutations3 = tifindallpermutations({ 1, 2, 3 })
  -- -- permutations3 is
  -- -- {
  -- --   { 2, 3, 1 },
  -- --   { 3, 2, 1 },
  -- --   { 1, 3, 2 },
  -- --   { 3, 1, 2 },
  -- --   { 1, 2, 3 },
  -- --   { 2, 1, 3 }
  -- -- }
  --
  -- local permutations4 = tifindallpermutations({ 1, 2, 3, 4 })
  -- -- permutations4 is
  -- -- {
  -- --   { 3, 4, 2, 1 },
  -- --   { 4, 3, 2, 1 },
  -- --   { 2, 4, 3, 1 },
  -- --   { 4, 2, 3, 1 },
  -- --   { 2, 3, 4, 1 },
  -- --   { 3, 2, 4, 1 },
  -- --   { 3, 4, 1, 2 },
  -- --   { 4, 3, 1, 2 },
  -- --   { 1, 4, 3, 2 },
  -- --   { 4, 1, 3, 2 },
  -- --   { 1, 3, 4, 2 },
  -- --   { 3, 1, 4, 2 },
  -- --   { 2, 4, 1, 3 },
  -- --   { 4, 2, 1, 3 },
  -- --   { 1, 4, 2, 3 },
  -- --   { 4, 1, 2, 3 },
  -- --   { 1, 2, 4, 3 },
  -- --   { 2, 1, 4, 3 },
  -- --   { 2, 3, 1, 4 },
  -- --   { 3, 2, 1, 4 },
  -- --   { 1, 3, 2, 4 },
  -- --   { 3, 1, 2, 4 },
  -- --   { 1, 2, 3, 4 },
  -- --   { 2, 1, 3, 4 }
  -- -- }
  tifindallpermutations = function(t, results)
    arguments(
        'table', t,
        'table', results
      )

    if #t == 0 then
      return
    elseif #t == 1 then
      results[#results + 1] = { t[1] }
      return
    elseif #t == 2 then
      results[#results + 1] = { t[1], t[2] }
      results[#results + 1] = { t[2], t[1] }
      return
    end

    for i = 1, #t do
      local rest = { }
      local rest_permutations = { }
      for j = 1, #t do
        if j ~= i then
          rest[#rest + 1] = t[j]
        end
      end

      tifindallpermutations(rest, rest_permutations)

      for j = 1, #rest_permutations do
        local permutation = rest_permutations[j]
        permutation[#permutation + 1] = t[i]
        results[#results + 1] = permutation
      end
    end
  end
end

--------------------------------------------------------------------------------

local tproxymt = function(...)
  local nargs = select('#', ...)
  local args = { ... }

  local cache = setmetatable({ }, {
    __index = function(t, k)
      for i = 1, nargs do
        local v = args[i][k]
        if v ~= nil then
          t[k] = v
          return v
        end
      end
      return nil
    end;
  })

  return { __index = cache }
end

--------------------------------------------------------------------------------

local tgetpatht = function(t, path)
  if not is_table(path) then
    return t[path] -- For convenience.
  end

  for i = 1, #path do
    t = t[path[i]]
    if t == nil then
      return nil
    end
  end

  return t
end

--------------------------------------------------------------------------------

return
{
  empty_table = empty_table;
  toverride_many = toverride_many;
  tappend_many = tappend_many;
  tijoin_many = tijoin_many;
  tkeys = tkeys;
  tvalues = tvalues;
  tkeysvalues = tkeysvalues;
  tflip = tflip;
  tflip_inplace = tflip_inplace;
  tiflip = tiflip;
  tset = tset;
  tiset = tiset;
  tisarray_not = tisarray_not;
  tisarray = tisarray;
  tiinsert_args = tiinsert_args;
  timap_inplace = timap_inplace;
  timap = timap;
  timap_sliding = timap_sliding;
  tiwalk = tiwalk;
  tiwalker = tiwalker;
  tequals = tequals;
  tiunique = tiunique;
  tgenerate_n = tgenerate_n; -- deprecated
  tgenerate_1d_linear = tgenerate_1d_linear;
  tgenerate_2d_linear = tgenerate_2d_linear;
  taccumulate = taccumulate;
  tnormalize = tnormalize;
  tnormalize_inplace = tnormalize_inplace;
  tclone = tclone;
  tcount_elements = tcount_elements;
  tremap_to_array = tremap_to_array;
  twalk_pairs = twalk_pairs;
  tmap_values = tmap_values;
  torderedset = torderedset;
  torderedset_insert = torderedset_insert;
  torderedset_remove = torderedset_remove;
  twithdefaults = twithdefaults;
  tifilter = tifilter;
  tsetof = tsetof;
  tset_many = tset_many;
  tidentityset = tidentityset;
  timapofrecords = timapofrecords;
  tivalues = tivalues;
  treadonly = treadonly;
  treadonly_ex = treadonly_ex;
  tmap_kv = tmap_kv;
  tmapofrecordgroups = tmapofrecordgroups;
  timapofrecordgroups = timapofrecordgroups;
  tilistofrecordfields = tilistofrecordfields;
  tipermute_inplace = tipermute_inplace;
  tkvtorecordlist = tkvtorecordlist;
  tgetpath = tgetpath;
  tsetpath = tsetpath;
  tsetpathvalue = tsetpathvalue;
  tslice = tslice;
  tarraylisttohashlist = tarraylisttohashlist;
  tarraytohash = tarraytohash;
  tkvlist2kvpairs = tkvlist2kvpairs;
  tfilterkeylist = tfilterkeylist;
  tisempty = tisempty;
  tifindvalue_nonrecursive = tifindvalue_nonrecursive;
  tkvmap_unpack = tkvmap_unpack;
  tkvlist_to_hash = tkvlist_to_hash;
  tmerge_many = tmerge_many;
  tdeepfilter = tdeepfilter;
  tifindallpermutations = tifindallpermutations;
  tproxymt = tproxymt;
  tgetpatht = tgetpatht;
}
