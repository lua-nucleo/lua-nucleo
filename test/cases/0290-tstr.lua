--------------------------------------------------------------------------------
-- 0290-tstr.lua: tests for visualization of non-recursive tables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local tstr,
      tstr_exports
      = import 'lua-nucleo/tstr.lua'
      {
        'tstr'
      }

--------------------------------------------------------------------------------

local test = make_suite("tstr", tstr_exports)

--------------------------------------------------------------------------------

test:group "tstr"
test:TODO "tstr all tests"
-- https://redmine.iphonestudio.ru/issues/3878

-- Test based on real bug scenario
-- #3836
test "tstr-serialize-inf-bug" (function ()
  local table_with_inf = "{1/0,-1/0,0/0}"

  ensure_strequals(
    "second result matches expected",
    ensure(
      "render second",
      tstr(
        ensure("parse error", loadstring("return " .. table_with_inf))()
      )
    ),
    table_with_inf
  )
end)

--------------------------------------------------------------------------------

test:UNTESTED 'tstr_cat'

--------------------------------------------------------------------------------

assert(test:run())
