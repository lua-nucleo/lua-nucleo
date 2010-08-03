-- 0205-tdeepequals-other-functions.lua: tests for other tdeepequals functions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

--------------------------------------------------------------------------------

local less_kv,
      tless_kv,
      tsort_kv
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'less_kv',
        'tless_kv',
        'tsort_kv'
      }


--------------------------------------------------------------------------------

local test = make_suite("tdeepequals-other-functions")

--------------------------------------------------------------------------------

test:UNTESTED 'less_kv'

test:UNTESTED 'tless_kv'

test:UNTESTED 'tsort_kv'

--------------------------------------------------------------------------------

assert(test:run())
