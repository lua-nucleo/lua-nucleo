-- ----------------------------------------------------------------------------
-- tserialize.lua - tests for tserialize module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
-- ----------------------------------------------------------------------------

local randomseed = 1235134892
--local randomseed = os.time()

math.randomseed(randomseed)
-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------

local invariant = function(v)
  return function()
    return v
  end
end

local escape_string = function(str)
  return str:gsub(
      "[^0-9A-Za-z_%- :]",
      function(c)
        return ("%%%02X"):format(c:byte())
      end
    )
end

local ensure_equals = function(msg, actual, expected)
  if actual ~= expected then
    error(
        msg..": actual `"..escape_string(tostring(actual))
        .."` expected `"..escape_string(tostring(expected)).."'"
      )
  end
end

local function deepequals(lhs, rhs)
  if type(lhs) ~= "table" or type(rhs) ~= "table" then
    return lhs == rhs
  end

  local checked_keys = {}

  for k, v in pairs(lhs) do
    checked_keys[k] = true
    if not deepequals(v, rhs[k]) then
      return false
    end
  end

  for k, v in pairs(rhs) do
    if not checked_keys[k] then
      return false -- extra key
    end
  end

  return true
end

local nargs = function(...)
  return select("#", ...), ...
end

local pack = function(...)
  return select("#", ...), { ... }
end


-- ----------------------------------------------------------------------------
-- Test helper functions
-- ----------------------------------------------------------------------------

local tserialize = assert((assert(import 'lua/tserialize.lua' ))())

local check_fn_ok = function(eq, ...)
  local saved = tserialize.tserialize(...)
  assert(type(saved) == "string")
  print("saved length", #saved, "(display truncated to 200 chars)")
  print(saved:sub(1, 200))
  local expected = { nargs(...) }
  local loaded = { nargs(assert(loadstring(saved))()) }
  ensure_equals("num arguments match",  loaded[1], expected[1])
  for i = 2, expected[1] do
    assert(eq(expected[i], loaded[i]))
  end
  return saved
end


local check_ok = function(...)
  print("check_ok started")
  local ret=check_fn_ok(deepequals, ...)
  if ret then
    print("check_ok successful")
    return true
  else
    print("check_ok failed")
    return false
  end
end

local check_fn_ok_link = function(links, ...)
  local saved = tserialize.tserialize(...)
  local loaded = {assert(loadstring(saved))()}
  for i=1,#links do
    local link=links[i]
    assert(loadstring("return (...)"..link[1].."==(...)"..link[2]))(loaded)
  end
  return saved
end

local check_ok_link = function(links,...)
  print("check_ok_link started")
  if not check_ok(...) then print("check_ok_link failed") return false end
  local ret=check_fn_ok_link(links, ...)
  if ret then
    print("check_ok_link successful")
  else
    print("check_ok_link failed")
  end
  return ret
end

return {check_ok=check_ok, check_ok_link=check_ok_link}
