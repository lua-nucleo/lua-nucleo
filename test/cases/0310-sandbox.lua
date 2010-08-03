-- 0310-sandbox.lua: tests for sandbox stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

--------------------------------------------------------------------------------

local make_config_environment,
      do_in_environment,
      dostring_in_environment,
      exports
      = import 'lua-nucleo/sandbox.lua'
      {
        'make_config_environment',
        'do_in_environment',
        'dostring_in_environment'
      }

--------------------------------------------------------------------------------

local test = make_suite("sandbox", exports)

--------------------------------------------------------------------------------

test:UNTESTED 'make_config_environment'

test:UNTESTED 'do_in_environment'

test:UNTESTED 'dostring_in_environment'

--------------------------------------------------------------------------------

assert(test:run())
