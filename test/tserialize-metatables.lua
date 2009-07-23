-- tserialize-autogen.lua -- checks if tserialize properly ignores metatables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)


dofile("lua/strict.lua")
local make_suite = select(1, ...)
assert(type(make_suite) == "function")
assert(type(import)=="function","Import is required to run")
local check_ok = import 'test/tserialize-test-utils.lua' { 'check_ok' }
-- ----------------------------------------------------------------------------
-- Link tests
-- ----------------------------------------------------------------------------
local test = make_suite("metatables test")

test "1" (function()
  do
    local a={1,2}
    local b={}
    setmetatable(a,b)
    check_ok(a)
  end
end)
test "2" (function()
  do
    local a={1,2,nil,4}
    local b={__index = (function(table, key) error("Metatable not ignored",2) end)}
    setmetatable(a,b)
    check_ok(a)
  end
end)

test "3" (function()
  do
    local a={1,2}
    a["123"]=16
    local b={__index = (function(table, key) error("Metatable not ignored",2) end)}
    setmetatable(a,b)
    check_ok(a)
  end
end)
assert (test:run())