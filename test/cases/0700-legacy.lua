--------------------------------------------------------------------------------
-- 0700-legacy.lua: tests for legacy function replacements implementations
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

--------------------------------------------------------------------------------

local loadstring,
      newproxy,
      setfenv,
      unpack,
      legacy_exports
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring',
        'newproxy',
        'setfenv',
        'unpack'
      }

--------------------------------------------------------------------------------

local test = make_suite("legacy", legacy_exports)

--------------------------------------------------------------------------------

test:UNTESTED 'loadstring'
test:UNTESTED 'newproxy'
test:UNTESTED 'setfenv'
test:UNTESTED 'unpack'
