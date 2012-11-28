--------------------------------------------------------------------------------
-- single-BROKEN-with-decorator-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("single-BROKEN-unstrict-mode-suite", { })
test:set_strict_mode(false)

local decorator = function(test_func)
  return function(test_env)
    return test_func(test_env)
  end
end

test:BROKEN "to_test" :with(decorator) (function()
  local counter = suite_tests_results + 1
end)
