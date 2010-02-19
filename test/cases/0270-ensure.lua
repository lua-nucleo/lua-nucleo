-- 0270-ensure.lua: tests for lua-nucleo ensure methods
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

-- TODO: write tests here
local test = make_suite("ensure", { })
test:TODO "ensure all tests"
--------------------------------------------------------------------------------
assert(test:run())
