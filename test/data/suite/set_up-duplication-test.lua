--------------------------------------------------------------------------------
-- set_up-duplication-test.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("set_up-duplication-test", { })

test:set_up (function() end)
test:set_up (function() end)
