-- tserialize-test-utils.lua -- utility functions for tserialize testing
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- ----------------------------------------------------------------------------
-- Test helper functions
-- ----------------------------------------------------------------------------
assert(type(import)=="function","Import is required to run")
local tdeepequals = import("lua-nucleo/tdeepequals.lua") {'tdeepequals'}
local tserialize = import 'lua-nucleo/tserialize.lua' {"tserialize"}
local escape_string = import 'lua-nucleo/string.lua' {'escape_string'}

local check_fn_ok = function(eq, ...)
  local saved = tserialize(...)
  assert(type(saved) == "string")
  print("saved length", #saved, "(display truncated to 1000 chars)")
  print(escape_string(saved:sub(1, 1000)))
  local expected = { ... }
  local loaded = { assert(loadstring(saved))() }
  assert(eq(expected, loaded), "tserialize produced wrong table!")
  return saved
end


local check_ok = function(...)
  print("check_ok started")
  local ret=check_fn_ok(tdeepequals, ...)
  if ret then
    print("check_ok successful")
    return true
  else
    print("check_ok failed")
    return false
  end
end

return {check_ok=check_ok}
