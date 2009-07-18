-- test.lua -- tests for all modules of the library
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- Note: can't use import here for the test purity reasons.
local run_tests = assert(assert(assert(loadfile('lua/suite.lua'))()).run_tests)

run_tests
{
 --[['suite';
 'strict';
 'import';--]]
 'tserialize-basic';
 'tserialize-link';
 'tserialize-metatables';
 'tdeepequals-basic-types';
 'tdeepequals-basic-tables';
 'tdeepequals-shared-subtables';
 'tdeepequals-userdata-functions-threads'
}
