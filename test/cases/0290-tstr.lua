--------------------------------------------------------------------------------
-- 0290-tstr.lua: tests for visualization of non-recursive tables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

-- TODO: write tests here
local test = make_suite("tstr", { })
test:TODO "tstr all tests"
--------------------------------------------------------------------------------
assert(test:run())
