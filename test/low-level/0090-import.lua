--------------------------------------------------------------------------------
-- 0090-import.lua: tests for import module without base path set
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- Intentionally not using test suite to avoid circular dependency questions.

local make_suite = assert(loadfile('test/test-lib/init/no-suite.lua'))(...)

local test_import = assert(assert(assert(loadfile("test/test-lib/import.lua"))())["test_import"])

test_import("test/data/")
