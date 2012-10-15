--------------------------------------------------------------------------------
-- single-set_fail_on_first_error-true-suite.lua: suite used for full suite
-- tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("single-set_fail_on_first_error-true-suite", { })
test:set_fail_on_first_error(true)
test "fail_one" (function()
  suite_tests_results = suite_tests_results + 1
  error("any error", 0)
end)
test "fail_two" (function()
  suite_tests_results = suite_tests_results + 10
  error("any error", 0)
end)
