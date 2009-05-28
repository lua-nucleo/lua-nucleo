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
local make_suite = select(1, ...)

dofile("lua/strict.lua")
dofile("lua/import.lua")
assert(type(make_suite) == "function")
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
-- ----------------------------------------------------------------------------
-- Basic tests
-- ----------------------------------------------------------------------------
local test = make_suite("syntetic basic tests")

test "1" ( function() check_ok() end)
test "2" ( function() check_ok(true) end)
test "3" ( function() check_ok(false) end)
test "4" ( function() check_ok(42) end)
test "5" ( function() check_ok(math.pi) end)
test "6" ( function() check_ok("serialize") end)
test "7" ( function() check_ok({ }) end)
test "8" ( function() check_ok({ a = 1, 2 }) end)
test "9" ( function() check_ok("") end)
test "10" ( function() check_ok("Embedded\0Zero") end)
test "11" ( function() check_ok(("longstring"):rep(1024000)) end)
test "12" ( function() check_ok({ 1 }) end)
test "13" ( function() check_ok({ a = 1 }) end)
test "14" ( function() check_ok({ a = 1, 2, [42] = true, [math.pi] = 2 }) end)
test "15" ( function() check_ok({ { } }) end)
test "16" ( function() check_ok({ a = {}, b = { c = 7 } }) end)
test "17" ( function() check_ok(nil, false, true, 42, "Embedded\0Zero", { { [{3}] = 54 } }) end)
test "18" ( function() check_ok({ a = {}, b = { c = 7 } }, nil, { { } }, 42) end)
test "19" ( function() check_ok({ ["1"] = "str", [1] = "num" }) end)
test "20" ( function() check_ok({ [true] = true }) end)
test "21" ( function() check_ok({ [true] = true, [false] = false, 1 }) end)
assert (test:run())

local test = make_suite("syntetic link tests")
test "1" (function()
  do
    local a={}
    local b={a}
    check_ok_link({{"[1]","[2][1]"}},a,b)
  end
end)
test "2" (function()
  do
    local a={}
    local b={a}
    local c={b}
    check_ok_link({{"[1]","[2][1]"},{"[2]","[3][1]"},{"[1]","[3][1][1]"}},a,b,c)
  end
end)
test "3" (function()
  do
    local a={1,2,3}
    local b={[true]=a}
    local c={[true]=a}
    check_ok_link({{"[1]","[2][true]"},{"[1]","[3][true]"},{"[2][true]","[3][true]"}},a,b,c)
  end
end)
test "4" (function()
  do
    local a={1,2,3}
    local b={a,a,a,a}
    local c={a}
    check_ok_link({{"[1]","[2][1]"},{"[1]","[2][2]"},{"[1]","[2][3]"},{"[1]","[2][4]"},{"[3][1]","[1]"}},a,b,c)
  end
end)

assert (test:run())
