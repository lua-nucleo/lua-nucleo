--------------------------------------------------------------------------------
--- Utility functions for tserialize testing
-- @module test.test-lib.tserialize-test-utils
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local loadstring
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring'
      }

local tdeepequals = import 'lua-nucleo/tdeepequals.lua' { 'tdeepequals' }
local tserialize = import 'lua-nucleo/tserialize.lua' { 'tserialize' }
local escape_string = import 'lua-nucleo/string.lua' { 'escape_string' }
local ensure_equals = import 'lua-nucleo/ensure.lua' { 'ensure_equals' }
local pack = import 'lua-nucleo/args.lua' { 'pack' }

local check_fn_ok = function(eq, ...)
  local saved = tserialize(...)
  assert(type(saved) == "string")
  --[[
  print(
      "saved length", #saved,
      "(truncated to 100 chars, non-printable chars are urlencoded)"
    )
  print(escape_string(saved:sub(1, 100)))
  ]] -- commented due to massive output
  local ne, expected = pack (...)
  local nl, loaded = pack(assert(loadstring(saved))())
  ensure_equals("Returned values quantity", ne, nl)
  assert(eq(expected, loaded), "tserialize produced wrong table!")
  return saved
end

local check_ok = function(...)
  --print("check_ok started")
  local ret = check_fn_ok(tdeepequals, ...)
  if ret then
    --print("check_ok successful")
    return true
  else
    --print("check_ok failed")
    return false
  end
end

return
{
  check_ok = check_ok;
}
