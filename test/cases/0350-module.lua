-- 0350-module.lua: tests for lua-nucleo module bootstrapper
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

assert(
    loadfile('test/test-lib/init/no-suite-no-import.lua')
  )(...)

--------------------------------------------------------------------------------

require 'lua-nucleo.module'

assert(import ~= nil)

local test_import = assert(
    assert(assert(loadfile("test/test-lib/import.lua"))())["test_import"]
  )

test_import("test/data/")
