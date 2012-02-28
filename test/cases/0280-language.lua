--------------------------------------------------------------------------------
-- 0280-language.lua: tests for lua-nucleo Lua language definitions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

-- TODO: write tests here
local test = make_suite("language", { })
test:TODO "language all tests"
--------------------------------------------------------------------------------
assert(test:run())
