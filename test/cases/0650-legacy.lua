--------------------------------------------------------------------------------
-- 0650-legacy.lua: tests for replacements of legacy Lua functions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

local loadstring,
      legacy_exports
      = import "lua-nucleo/legacy.lua"
      {
        "loadstring"
      }

--------------------------------------------------------------------------------

local test = make_suite("legacy", legacy_exports)

--------------------------------------------------------------------------------

test:UNTESTED 'loadstring'
