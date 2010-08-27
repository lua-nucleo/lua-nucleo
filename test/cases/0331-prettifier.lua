-- 0331-tpretty.lua: tests for pretty-printer prettifier
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

local make_prettifier,
      prettifier_exports
      = import 'lua-nucleo/prettifier.lua'
      {
        'make_prettifier'
      }

--------------------------------------------------------------------------------

local test = make_suite("prettifier", prettifier_exports)

--------------------------------------------------------------------------------

test:factory("make_prettifier", make_prettifier)

--------------------------------------------------------------------------------

test:TODO "test make_prettifier"

--------------------------------------------------------------------------------

assert(test:run())
