-- timestamp.lua: timestamp-related utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

local os_time, os_date = os.time, os.date

--------------------------------------------------------------------------------

local get_day_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local time_table = os_date("*t", timestamp)

  time_table.hour = 3 -- To protect from DST changes
  time_table.min = 0
  time_table.sec = 0

  return os_time(time_table), timestamp
end

local get_yesterday_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  return get_day_timestamp(timestamp - 60 * 60 * 24)
end

--------------------------------------------------------------------------------

return
{
  get_day_timestamp = get_day_timestamp;
  get_yesterday_timestamp = get_yesterday_timestamp;
}
