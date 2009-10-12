-- tserialize-autogen.lua: checks if tserialize properly ignores metatables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile("lua-nucleo/strict.lua")
dofile("lua-nucleo/import.lua")

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local check_ok = import 'test/lib/tserialize-test-utils.lua' { 'check_ok' }

---------------------------------------------------------------------------

local test = make_suite("metatables test")

---------------------------------------------------------------------------

test "Collectgarbage" (function()
  local changed = 0
  local tbl1 = {}
  local tbl2 = {}
  local u={tbl1, tbl2}
  local probe = setmetatable({ [tbl1] = true, [tbl2] = true }, { __mode = "k" })
  check_ok(u)
  tbl1 = nil
  tbl2 = nil
  u = nil
  local now = collectgarbage("count")
  local prev = 0
  while prev ~= now do
    collectgarbage("collect")
    prev, now = now, collectgarbage("count")
  end
  assert(not next(probe), "Garbage not collected")
end)

test "1" (function()
  local a = { 1, 2 }
  local b = { }
  setmetatable(a, b)
  check_ok(a)
end)

test "2" (function()
  local a = { 1, 2, nil, 4 }
  local b =
  {
    __index = function(t, k) error("Metatable not ignored (i)", 2) end;
    __newindex = function(t, k) error("Metatable not ignored (n)", 2) end;
  }
  setmetatable(a, b)
  check_ok(a)
end)

test "3" (function()
  local a = { 1, 2 }
  a["123"] = 16
  local b =
  {
    __index = function(t, k) error("Metatable not ignored (i)", 2) end;
    __newindex = function(t, k) error("Metatable not ignored (n)", 2) end;
  }
  setmetatable(a, b)
  check_ok(a)
end)

---------------------------------------------------------------------------

assert(test:run())
