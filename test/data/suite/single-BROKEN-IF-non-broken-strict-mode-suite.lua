--------------------------------------------------------------------------------
-- single-BROKEN-IF-non-broken-strict-mode-suite.lua: suite used for full suite
-- tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite(
    "single-BROKEN-IF-non-broken-strict-mode-suite",
    {
      non_broken_test2 = true;
      non_broken_test3 = true;
    }
  )
test:set_strict_mode(true)
test:BROKEN_IF(false):test_for "non_broken_test2" (function()
  suite_tests_results = suite_tests_results + 1
end)
test:test_for("non_broken_test3"):BROKEN_IF(false) (function()
  suite_tests_results = suite_tests_results + 1
end)
