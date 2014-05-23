--------------------------------------------------------------------------------
-- skip-slow-test.lua: skip slow tests suite
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local test = make_suite("filter-test-names")
assert(type(test) == "table", "suite object 'test' is table'")

test "100" (function()
  suite_tests_results.counter = suite_tests_results.counter + 100
end)

test "10" (function()
  suite_tests_results.counter = suite_tests_results.counter + 10
end)

test "1" (function()
  suite_tests_results.counter = suite_tests_results.counter + 1
end)
