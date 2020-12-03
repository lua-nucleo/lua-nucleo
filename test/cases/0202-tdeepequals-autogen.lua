--------------------------------------------------------------------------------
-- 0202-tdeepequals-autogen.lua: autogenerated random tests for tdeepequals package
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local loadstring
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring'
      }

local check_ok = import 'test/test-lib/tdeepequals-test-utils.lua' { 'check_ok' }
local tserialize = import "lua-nucleo/tserialize.lua" { 'tserialize' }

local gen_random_dataset,
      mutate =
      import 'test/test-lib/table.lua'
      {
        'gen_random_dataset',
        'mutate'
      }

---------------------------------------------------------------------------

local test = make_suite("Autogenerated tests")

---------------------------------------------------------------------------

test "Random tests 1-500" (function()
  for i = 1, 500 do
    local c = gen_random_dataset(1)
    check_ok(c, c, true)
  end
end)

test "Random mutated test 1-500" (function()
  for i = 1, 500 do
    local c1 = gen_random_dataset(1)
    local str = tserialize(c1)
    local ch = loadstring(str)
    local rez, c2 = mutate(ch())
    check_ok(c1, c2, not rez)
  end
end)
