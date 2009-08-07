-- test.lua -- tests for all modules of the library
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- Note: can't use import here for the test purity reasons.
local run_tests = assert(assert(assert(loadfile('lua/suite.lua'))()).run_tests)
dofile('lua/import.lua')

local tests_pr =
{
  'suite';
  'strict';
  'import';
  --
  'tserialize-basic';
  'tserialize-recursive';
  'tserialize-metatables';
  'tserialize-autogen';
  --
  'tdeepequals-basic-types';
  'tdeepequals-basic-tables';
  'tdeepequals-recursive';
  'tdeepequals-userdata-functions-threads';
  'tdeepequals-autogen';
  --
  'coro';
  'functional';
  'algorithm';
  --
  'util/anim/interpolator';
}

local pattern = select(1, ...) or ""
assert(type(pattern) == "string")

local test_r = {}
for _, v in ipairs(tests_pr) do
  if string.match(v, pattern) then
    test_r[#test_r + 1] = v
  end
end

run_tests(test_r)
