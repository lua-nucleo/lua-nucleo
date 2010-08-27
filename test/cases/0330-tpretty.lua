-- 0330-tpretty.lua: tests for pretty-printer
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local tpretty,
      tpretty_exports
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty'
      }

--------------------------------------------------------------------------------

local test = make_suite("tpretty", tpretty_exports)

--------------------------------------------------------------------------------

test:UNTESTED "tpretty"

--------------------------------------------------------------------------------

assert(test:run())
