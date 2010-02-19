-- 0300-generate-test-list.lua: tests for test list generation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

-- TODO: write tests here
local test = make_suite("generate-test-list", { })
test "generate-test-list" (function()
  --uninstall_strict_mode_()
  loadfile('test/test-lib/generate-test-list.lua')("test/data/generate-test-list/lib test/data/generate-test-list/cases")
end)
--------------------------------------------------------------------------------
assert(test:run())
