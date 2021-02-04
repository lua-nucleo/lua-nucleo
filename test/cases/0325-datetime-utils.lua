--------------------------------------------------------------------------------
-- 0325-datetime-utils.lua: tests for date and time related utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

--------------------------------------------------------------------------------

local make_time_table,
      get_days_in_month,
      get_day_of_week,
      day_of_week_name_to_number,
      month_name_to_number,
      exports
      = import 'lua-nucleo/datetime-utils.lua'
      {
        'make_time_table',
        'get_days_in_month',
        'get_day_of_week',
        'day_of_week_name_to_number',
        'month_name_to_number'
      }

local ensure_equals,
      ensure
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure'
      }

--------------------------------------------------------------------------------

local test = make_suite("datetime-utils", exports)

--------------------------------------------------------------------------------

test:test_for 'get_days_in_month' (function()
  -- TODO: write more tests
  ensure_equals('days in Feb 2020 equals', get_days_in_month(2020, 2), 29)
  ensure_equals('days in Dec 2020 equals', get_days_in_month(2020, 12), 31)
end)

test:test_for 'get_day_of_week' (function()
  -- TODO: write more tests
  ensure_equals(
      'day of week for 2020-12-08 equals',
      get_day_of_week(os.time({ year = 2020, month = 12, day = 8 })),
      2
    )
end)

--------------------------------------------------------------------------------

test:UNTESTED 'make_time_table'
test:UNTESTED 'day_of_week_name_to_number'
test:UNTESTED 'month_name_to_number'
