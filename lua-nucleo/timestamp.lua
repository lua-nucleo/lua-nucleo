--------------------------------------------------------------------------------
-- timestamp.lua: timestamp-related utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local os_time, os_date = os.time, os.date

--------------------------------------------------------------------------------

local get_day_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local time_table = os_date("*t", timestamp)

  time_table.hour = 0
  time_table.min = 0
  time_table.sec = 0
  time_table.isdst = nil -- To protect from DST changes

  return os_time(time_table), timestamp
end

local get_yesterday_timestamp = function(timestamp)
  timestamp = timestamp or os_time()
  local time_table = os_date("*t", timestamp)
  time_table.isdst = nil -- To protect from DST changes
  time_table.day = time_table.day - 1
  return get_day_timestamp(os_time(time_table))
end

local get_tomorrow_timestamp = function(timestamp)
  timestamp = timestamp or os_time()
  local time_table = os_date("*t", timestamp)
  time_table.isdst = nil -- To protect from DST changes
  time_table.day = time_table.day + 1
  return get_day_timestamp(os_time(time_table))
end

local get_quarter_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os_date("*t", timestamp)

  t.sec = 0
  if t.min < 15 then
    t.min = 0
  elseif t.min < 30 then
    t.min = 15
  elseif t.min < 45 then
    t.min = 30
  else
    t.min = 45
  end

  return os_time(t)
end

local get_minute_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os_date("*t", timestamp)

  t.sec = 0

  return os_time(t)
end

local get_decasecond_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os_date("*t", timestamp)

  t.sec = t.sec - t.sec % 10

  return os_time(t)
end

--------------------------------------------------------------------------------

return
{
  get_day_timestamp = get_day_timestamp;
  get_yesterday_timestamp = get_yesterday_timestamp;
  get_tomorrow_timestamp = get_tomorrow_timestamp;
  get_quarter_timestamp = get_quarter_timestamp;
  get_minute_timestamp = get_minute_timestamp;
  get_decasecond_timestamp = get_decasecond_timestamp;
}
