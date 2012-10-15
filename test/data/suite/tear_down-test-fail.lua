--------------------------------------------------------------------------------
-- tear_down-test-fail.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("tear_down-test-fail", { })

test:tear_down (function() error("expected error") end)
test "any" (function() end)
