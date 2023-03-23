--------------------------------------------------------------------------------
-- 0365-ordered_keys.lua: tests for ordered keys module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local table_sort = table.sort

local ensure,
      ensure_equals,
      ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals'
      }

local keys_to_order,
      keys_less,
      ordered_key_pairs,
      exports
      = import 'lua-nucleo/ordered_keys.lua'
      {
        'keys_to_order',
        'keys_less',
        'ordered_key_pairs'
      }

--------------------------------------------------------------------------------

local test = make_suite("ordered_keys", exports)

--------------------------------------------------------------------------------

test:test_for "keys_to_order" (function()
  ensure_tequals(
    "set keys to order",
    keys_to_order({}),
    {}
  )

  ensure_tequals(
    "set keys to order",
    keys_to_order({ 'a', 'b', 'c' }),
    { a = 1, b = 2, c = 3 }
  )
end)

test:test_for "keys_less" (function()
  ensure(
    "'a' less than 'b' with empty keys table",
    keys_less({})('a', 'b')
  )

  ensure(
    "'a' less than 'b' with random keys table",
    keys_less({ 'd', 'e' })('a', 'b')
  )

  ensure(
    "'b' less than 'a' with pre ordered keys table",
    not keys_less({ 'b', 'a' })('a', 'b')
  )

  ensure(
    "'b' less than 'a' with pre ordered keys table containing indicies",
    not keys_less({ ['a'] = 2, ['b'] = 1 }, true)('a', 'b')
  )

  ensure(
    "keys table ignored without indicies and specified pre_ordered optional",
    keys_less({ 'b', 'a' }, true)('a', 'b')
  )

  ensure(
    "pre ordered table ignored without specified pre_ordered optional",
    not keys_less({ ['b'] = 1, ['a'] = 2 })('b', 'a')
  )
end)

test:test_for "ordered_key_pairs" (function()
  local test = { a = 'A', b = 'B' }
  local stringSorted = "bBaA"
  local stringTest = ""
  
  for k, v in ordered_key_pairs(test, { 'b', 'a' }) do
    stringTest = stringTest .. k  .. v 
  end

  ensure_equals(
    "sort by pre ordered keys table",
    stringTest,
    stringSorted
  )

  stringTest = ""

  for k, v in ordered_key_pairs(test, { ['a'] = 2, ['b'] = 1 }, true) do
    stringTest = stringTest .. k  .. v 
  end

  ensure_equals(
    "sort by pre ordered indexed keys table",
    stringTest,
    stringSorted
  )
end)
