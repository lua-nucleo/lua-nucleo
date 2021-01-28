--------------------------------------------------------------------------------
-- single-BROKEN-strict-mode-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite(
    "single-BROKEN-IF-non-broken-strict-mode-suite",
    {
      to_test2 = true;
      to_test3 = true;
    }
  )

test:set_strict_mode(true)
declare('socket') require('mobdebug').start('172.28.240.1')
test:BROKEN_IF(false) "to_test1" (function()
  suite_tests_results = suite_tests_results + 1
end)
test:BROKEN_IF(false):test_for "to_test2" (function()
  suite_tests_results = suite_tests_results + 1
end)
test:test_for("to_test3"):BROKEN_IF(false) (function()
  suite_tests_results = suite_tests_results + 1
end)
