-- test.lua -- tests for all modules of the library
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- Note: can't use import here for the test purity reasons.
local run_tests = assert(assert(assert(loadfile('lua/suite.lua'))()).run_tests)

local tests_pr={
 'suite';
 'strict';
 'import';
 'tserialize-basic';
 'tserialize-link';
 'tserialize-metatables';
 'tserialize-autogen';
 'tdeepequals-basic-types';
 'tdeepequals-basic-tables';
 'tdeepequals-shared-subtables';
 'tdeepequals-userdata-functions-threads';
 'tdeepequals-autogen';
}

local pattern=select(1,...) or ""
assert(type(pattern)=="string")

local test_r={}
for _,v in ipairs(tests_pr) do
  if(string.match(v,pattern)) then
    table.insert(test_r,v)
  end
end

run_tests(test_r)
