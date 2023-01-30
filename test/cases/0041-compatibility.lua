--------------------------------------------------------------------------------
-- 0041-compatibility: tests for compatibility module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure_equals = import 'lua-nucleo/ensure.lua' { 'ensure_equals' }

local setfenv = import 'lua-nucleo/compatibility.lua' { 'setfenv' }

--------------------------------------------------------------------------------

local test = make_suite("compatibility")

--------------------------------------------------------------------------------

test:test_for "setfenv" (function()
  local test_function = function()
    return print == nil and test_value == "test_value"
  end

  local test_environment = {test_value = "test_value"}

  ensure_equals(
    "Check function environment variables",
    setfenv(test_function, test_environment)(),
    true
    )
end)
