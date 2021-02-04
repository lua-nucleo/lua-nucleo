--------------------------------------------------------------------------------
-- 0650-enumerator.lua: tests for enumerator tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

local ensure_equals,
      ensure
      = import "lua-nucleo/ensure.lua"
      {
        "ensure_equals",
        "ensure"
      }

local make_enumerator_from_set,
      make_enumerator_from_interval,
      exports
      = import "lua-nucleo/enumerator.lua"
      {
        "make_enumerator_from_set",
        "make_enumerator_from_interval"
      }

--------------------------------------------------------------------------------

local test = make_suite("enumerator", exports)

--------------------------------------------------------------------------------

test:test_for  "make_enumerator_from_set" (function()
  local enumerator = make_enumerator_from_set({ 1, 2, 3, 5, 8 })

  ensure('not contains -1', not enumerator:contains(-1))
  ensure('not contains 0', not enumerator:contains(0))
  ensure(    'contains 1',     enumerator:contains(1))
  ensure(    'contains 2',     enumerator:contains(2))
  ensure(    'contains 3',     enumerator:contains(3))
  ensure('not contains 4', not enumerator:contains(4))
  ensure(    'contains 5',     enumerator:contains(5))
  ensure('not contains 6', not enumerator:contains(6))
  ensure('not contains 7', not enumerator:contains(7))
  ensure(    'contains 8',     enumerator:contains(8))
  ensure('not contains 9', not enumerator:contains(9))

  ensure_equals('first element matches', enumerator:get_first(), 1)

  ensure_equals('next element matches', enumerator:get_next(-100), 1)
  ensure_equals('next element matches', enumerator:get_next(-1), 1)
  ensure_equals('next element matches', enumerator:get_next(0), 1)
  ensure_equals('next element matches', enumerator:get_next(1), 1)
  ensure_equals('next element matches', enumerator:get_next(2), 2)
  ensure_equals('next element matches', enumerator:get_next(3), 3)
  ensure_equals('next element matches', enumerator:get_next(4), 5)
  ensure_equals('next element matches', enumerator:get_next(5), 5)
  ensure_equals('next element matches', enumerator:get_next(6), 8)
  ensure_equals('next element matches', enumerator:get_next(7), 8)
  ensure_equals('next element matches', enumerator:get_next(8), 8)
  ensure_equals('next element matches', enumerator:get_next(9), nil)
  ensure_equals('next element matches', enumerator:get_next(10), nil)
  ensure_equals('next element matches', enumerator:get_next(100), nil)
end)

test:test_for  "make_enumerator_from_interval" (function()
  local enumerator = make_enumerator_from_interval(21, 23)

  ensure('not contains -1', not enumerator:contains(-1))
  ensure('not contains 0', not enumerator:contains(0))
  ensure(    'contains 21',     enumerator:contains(21))
  ensure(    'contains 22',     enumerator:contains(22))
  ensure(    'contains 23',     enumerator:contains(23))
  ensure('not contains 24', not enumerator:contains(24))
  ensure('not contains 25', not enumerator:contains(25))

  ensure_equals('first element matches', enumerator:get_first(), 21)

  ensure_equals('next element matches', enumerator:get_next(-100), 21)
  ensure_equals('next element matches', enumerator:get_next(-1), 21)
  ensure_equals('next element matches', enumerator:get_next(0), 21)
  ensure_equals('next element matches', enumerator:get_next(1), 21)
  ensure_equals('next element matches', enumerator:get_next(21), 21)
  ensure_equals('next element matches', enumerator:get_next(22), 22)
  ensure_equals('next element matches', enumerator:get_next(23), 23)
  ensure_equals('next element matches', enumerator:get_next(24), nil)
  ensure_equals('next element matches', enumerator:get_next(25), nil)
  ensure_equals('next element matches', enumerator:get_next(100), nil)
end)
