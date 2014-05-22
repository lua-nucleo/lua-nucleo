--------------------------------------------------------------------------------
-- skip-slow-test.lua: skip slow tests suite
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local test = make_suite("skip-slow-test")
assert(type(test) == "table", "suite object 'test' is table'")

test "is run no matter quick option passed" (function()
  suite_tests_results.counter = suite_tests_results.counter + 1
end)

test:SLOW "is not run if quick option passed" (function()
  suite_tests_results.counter = suite_tests_results.counter + 2
end)
