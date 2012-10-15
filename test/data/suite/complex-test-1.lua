--------------------------------------------------------------------------------
-- complex-test-1: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local make_another = function()
  local method1 = function() end
  local method2 = function() end
  local method3 = function() end
  return
  {
    method1 = method1,
    method2 = method2,
    method3 = method3
  }
end

local test = make_suite(
    "complex-test-1",
    {
      make_another = true,
      func1 = true,
      func2 = true,
      func3 = true,
      func4 = true
    }
  )

test:set_strict_mode(false)
test "any" (function()
  suite_tests_results = suite_tests_results * 2
end)
test:test_for "func1" (function()
  suite_tests_results = suite_tests_results * 3
end)
test:tests_for "func2"
test:case "func2_one" (function()
  if test:in_strict_mode() then
    suite_tests_results = suite_tests_results * 5
  end
end)

test "func2_two" (function()
  suite_tests_results = suite_tests_results * 7
  error("Expected error.")
end)

test:UNTESTED "func3"
test:TODO "TODOs can duplicate func names"
test:TODO "func4"
test:test_for "func4" (function() end)

test:factory "make_another" (make_another)
test:method "method1" (function()
  suite_tests_results = suite_tests_results * 11
end)
test:methods "method2" "method3"
