--------------------------------------------------------------------------------
-- 0350-init.lua: tests for standalone lua-nucleo initialization
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- Intentionally not using test suite to avoid circular dependency questions.

require 'lua-nucleo'

assert(import ~= nil)
assert(declare ~= nil)

local test_import = assert(
    assert(assert(loadfile("test/test-lib/import.lua"))())["test_import"]
  )

test_import("test/data/")

print("------> Init tests suite PASSED")
