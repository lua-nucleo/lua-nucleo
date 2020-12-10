--------------------------------------------------------------------------------
-- 0460-diagnostics.lua: Tests code diagnostics utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local loadstring = loadstring or function(code, chunkname)
  return load(code, chunkname, 't')
end

--------------------------------------------------------------------------------

local ensure_tdeepequals,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_tdeepequals',
        'ensure_equals'
      }

local capture_source_location,
      diagnostics_exports
      = import 'lua-nucleo/diagnostics.lua'
      {
        'capture_source_location'
      }

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)
local test = make_suite("diagnostics", diagnostics_exports)

--------------------------------------------------------------------------------

test:tests_for 'capture_source_location'

--------------------------------------------------------------------------------

test:case "csl-ok" (function()
  local MARKER = "csl-ok-test-code"

  -- Loading code from string to precisely control line numbers and filename
  local code = [[
local capture_source_location               -- 01
      = import 'lua-nucleo/diagnostics.lua' -- 02
      {                                     -- 03
        'capture_source_location'           -- 04
      }                                     -- 05
return function(fn)                         -- 06
  if fn then                                -- 07
    fn()                                    -- 08 "inner"
  end                                       -- 09
  local l = capture_source_location()       -- 10 "outer" (preventing tail call)
  return l                                  -- 11
end                                         -- 12
]]
  local chain = assert(assert(loadstring(code, "=" .. MARKER))())

  local inner_location = nil
  local outer_location = chain(function()
    inner_location = capture_source_location(2)
  end)

  ensure_tdeepequals(
      "outer location captured",
      outer_location,
      {
        source = "=" .. MARKER;
        file = MARKER;
        line = 10;
      }
    )

  ensure_tdeepequals(
      "inner location captured",
      inner_location,
      {
        source = "=" .. MARKER;
        file = MARKER;
        line = 8;
      }
    )
end)

--------------------------------------------------------------------------------

test:case "csl-outside-call-stack" (function()
  ensure_equals(
      "outside call stack",
      capture_source_location(42),
      nil
    )
end)

--------------------------------------------------------------------------------
