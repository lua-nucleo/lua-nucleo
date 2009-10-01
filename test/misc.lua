-- misc.lua: tests for various useful stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua') -- Import module requires strict
dofile('lua-nucleo/import.lua') -- Import module should be loaded manually

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

local unique_object,
      misc
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

--------------------------------------------------------------------------------

local test = make_suite("misc", misc)

--------------------------------------------------------------------------------

test:test_for "unique_object" (function()
  -- A bit silly, but how to test it better?
  local N = 100

  local data = { }
  for i = 1, N do
    data[unique_object()] = true
  end

  local count = 0
  for k, v in pairs(data) do
    count = count + 1
  end

  ensure_equals("all objects are unique", count, N)
end)

--------------------------------------------------------------------------------

assert(test:run())
