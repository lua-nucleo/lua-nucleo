--------------------------------------------------------------------------------
-- set_strict_mode-true-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("set_strict_mode-true-suite", { to_test = true })
test:set_strict_mode(true)
test:UNTESTED "to_test"
test "any" (function()
  suite_tests_results = suite_tests_results + 1
  if test:in_strict_mode() then
    suite_tests_results = suite_tests_results + 10
  end
end)
assert(test:in_strict_mode(), "test must be in strict mode")
