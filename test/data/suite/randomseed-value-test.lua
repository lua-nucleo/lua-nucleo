--------------------------------------------------------------------------------
-- randomseed-value-test.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("randomseed-value-test", { })

test "any" (function()
  suite_tests_results.value = math.random()
end)
test "any_other" (function()
  suite_tests_results.other_value = math.random()
end)
