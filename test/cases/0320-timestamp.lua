-- 0310-timestamp.lua: tests for timestamp-related utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

--------------------------------------------------------------------------------

local get_day_timestamp,
      get_yesterday_timestamp,
      get_tomorrow_timestamp,
      get_quarter_timestamp,
      get_minute_timestamp,
      exports
      = import 'lua-nucleo/timestamp.lua'
      {
        'get_day_timestamp',
        'get_yesterday_timestamp',
        'get_tomorrow_timestamp',
        'get_quarter_timestamp',
        'get_minute_timestamp'
      }

--------------------------------------------------------------------------------

local test = make_suite("timestamp", exports)

--------------------------------------------------------------------------------

test:UNTESTED 'get_day_timestamp'

test:UNTESTED 'get_yesterday_timestamp'

test:UNTESTED 'get_tomorrow_timestamp'

test:UNTESTED 'get_quarter_timestamp'

test:UNTESTED 'get_minute_timestamp'

--------------------------------------------------------------------------------

assert(test:run())
