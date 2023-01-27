--------------------------------------------------------------------------------
-- 0205-tdeepequals-other-functions.lua: tests for other tdeepequals functions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)
local check_ok = import 'test/test-lib/tdeepequals-test-utils.lua' { 'check_ok' }

--------------------------------------------------------------------------------

local less_kv,
      tless_kv,
      tsort_kv,
      ordered_pairs,
      tmore
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'less_kv',
        'tless_kv',
        'tsort_kv',
        'ordered_pairs',
        'tmore'
      }

--------------------------------------------------------------------------------

local test = make_suite("tdeepequals-other-functions")

--------------------------------------------------------------------------------

-- Test based on real bug scenario -- https://github.com/lua-nucleo/lua-nucleo/issues/31
test 'Test ordered_pairs()' (function()
  local t1 = {b = {}}
  local t2 = {a = {}}
  local test = {[t1] = '', [t2] = ''}
  local ordered = {t2, t1}

  local i = 1
  for k, v in ordered_pairs(test) do
    check_ok(ordered[i], k, true)
    i = i + 1
  end
end)

test 'Test ordered_pairs() with custom order function' (function()
  local t1 = {a = {}}
  local t2 = {b = {}}
  local test = {[t1] = '', [t2] = ''}
  local ordered = {t2, t1}

  local order_function = function(lhs, rhs)
    return tmore(lhs, rhs) > 0
  end

  local i = 1
  for k, _ in ordered_pairs(test, order_function) do
    check_ok(ordered[i], k, true)
    i = i + 1
  end
end)

test:UNTESTED 'less_kv'

test:UNTESTED 'tless_kv'

test:UNTESTED 'tsort_kv'
