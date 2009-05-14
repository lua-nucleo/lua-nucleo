-- ----------------------------------------------------------------------------
-- test.lua
-- tserialize tests
-- ----------------------------------------------------------------------------

local randomseed = 1235134892
--local randomseed = os.time()

print("===== BEGIN TSERIALIZE TEST SUITE (seed " .. randomseed .. ") =====")
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

local tserialize_local = require 'tserialize'
assert(tserialize_local == tserialize)


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
  loaded = {assert(loadstring(saved))()}
  for i=1,#links do
    local link=links[i]
    assert(loadstring("return loaded"..link[1].."==loaded"..link[2])(), "broken link!")
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

print("===== BEGIN SYNTETIC BASIC TESTS =====")


do
  local s
  s = check_ok()
 --s = check_ok(nil)
  s = check_ok(true)
  s = check_ok(false)
  s = check_ok(42)
  s = check_ok(math.pi)
  s = check_ok("serialize")
  s = check_ok({ })
  s = check_ok({ a = 1, 2 })
end

check_ok("")
check_ok("Embedded\0Zero")
check_ok(("longstring"):rep(1024000))
check_ok({ 1 })
check_ok({ a = 1 })
check_ok({ a = 1, 2, [42] = true, [math.pi] = 2 })
check_ok({ { } })
check_ok({ a = {}, b = { c = 7 } })
--check_ok(nil, nil)

do
  local s = check_ok(nil, false, true, 42, "Embedded\0Zero", { { [{3}] = 54 } })
end

check_ok({ a = {}, b = { c = 7 } }, nil, { { } }, 42)
check_ok({ ["1"] = "str", [1] = "num" })
check_ok({ [true] = true })
check_ok({ [true] = true, [false] = false, 1 })

print("===== BASIC SYNTETIC TESTS OK =====")


print("===== BEGIN SYNTETIC LINK TESTS =====")
do
  local a={}
  local b={a}
  check_ok_link({{"[1]","[2][1]"}},a,b)
end
do
  local a={}
  local b={a}
  local c={b}
  check_ok_link({{"[1]","[2][1]"},{"[2]","[3][1]"},{"[1]","[3][1][1]"}},a,b,c)
end

do
  local a={1,2,3}
  local b={[true]=a}
  local c={[true]=a}
  check_ok_link({{"[1]","[2][true]"},{"[1]","[3][true]"},{"[2][true]","[3][true]"}},a,b,c)
end

do
  local a={1,2,3}
  local b={a,a,a,a}
  check_ok_link({{"[1]","[2][1]"},{"[1]","[2][2]"},{"[1]","[2][3]"},{"[1]","[2][4]"},},a,b)
end

print("===== BASIC SYNTETIC LINK TESTS OK =====")
