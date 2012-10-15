--------------------------------------------------------------------------------
-- single-test_for-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("single-test_for-suite", { to_test = true })
test:test_for "to_test" (function()
  suite_tests_results = suite_tests_results + 1
end)
