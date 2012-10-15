--------------------------------------------------------------------------------
-- simple-test-2.lua: suite used for simple suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local test = make_suite("simple-test-2")
assert(type(test) == "table", "suite object 'test' is table'")

assert(pcall(function() test "a" (false) end) == false)

assert(suite_tests_results.to_call['1'] == true, "to_call['1'] must be true")
test '1' (function()
  if suite_tests_results.next_i ~= 1 then
    suite_tests_results.next_i = false
  else
    suite_tests_results.next_i = 2
  end
  suite_tests_results.to_call['1'] = nil
end)
assert(suite_tests_results.to_call['1'] == true, "to_call['1'] must be true")

assert(suite_tests_results.to_call['2'] == true, "to_call['2'] must be true")
assert(suite_tests_results.to_call['3'] == true, "to_call['3'] must be true")

test '2' (function()
  if suite_tests_results.next_i ~= 2 then
    suite_tests_results.next_i = false
  else
    suite_tests_results.next_i = 3
  end
  suite_tests_results.to_call['2'] = nil
  error("this error is expected")
end)

test '3' (function()
  if suite_tests_results.next_i ~= 3 then
    suite_tests_results.next_i = false
  else
    suite_tests_results.next_i = true
  end
  suite_tests_results.to_call['3'] = nil
end)
