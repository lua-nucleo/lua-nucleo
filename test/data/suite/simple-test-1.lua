--------------------------------------------------------------------------------
-- simple-test-1.lua: suite used for simple suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local test = make_suite("simple-test-1")
assert(type(test) == "table", "suite object 'test' is table'")

assert(pcall(function() test "a" (false) end) == false)

assert(suite_tests_results.to_call['1'] == true)

test '1' (function()
  if suite_tests_results.next_i ~= 1 then
    suite_tests_results.next_i = false
  else
    suite_tests_results.next_i = 2
  end
  suite_tests_results.to_call['1'] = nil
end)
assert(suite_tests_results.to_call['1'] == true)
