--------------------------------------------------------------------------------
--- Timestamp-related utilities
-- @module lua-nucleo.timestamp
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local os_time, os_date = os.time, os.date

local make_time_table
      = import 'lua-nucleo/datetime-utils.lua'
      {
        'make_time_table'
      }

--------------------------------------------------------------------------------

---
-- @tparam number timestamp
-- @treturn number,number
local get_day_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local time_table = os_date("*t", timestamp)

  time_table.hour = 0
  time_table.min = 0
  time_table.sec = 0
  time_table.isdst = nil -- To protect from DST changes

  return os_time(time_table), timestamp
end

---
-- @tparam number timestamp
-- @treturn number,number
local get_yesterday_timestamp = function(timestamp)
  timestamp = timestamp or os_time()
  local time_table = os_date("*t", timestamp)
  time_table.isdst = nil -- To protect from DST changes
  time_table.day = time_table.day - 1
  return get_day_timestamp(os_time(time_table))
end

---
-- @tparam number timestamp
-- @treturn number,number
local get_tomorrow_timestamp = function(timestamp)
  timestamp = timestamp or os_time()
  local time_table = os_date("*t", timestamp)
  time_table.isdst = nil -- To protect from DST changes
  time_table.day = time_table.day + 1
  return get_day_timestamp(os_time(time_table))
end

---
-- @tparam number timestamp
-- @treturn number
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

---
-- @tparam number timestamp
-- @treturn number
local get_minute_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os_date("*t", timestamp)

  t.sec = 0

  return os_time(t)
end

---
-- @tparam number timestamp
-- @treturn number
local get_decasecond_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os_date("*t", timestamp)

  t.sec = t.sec - t.sec % 10

  return os_time(t)
end

--- Convert Unix time to the (year, month, day, hour, minute, second) tuple.
-- @tparam[opt=<code>os_time()</code>] number timestamp Optional timestamp in
--                                     the Unix/POSIX time format.
-- @treturn number,number,number,number,number,number Year, month, day of month,
--          hour, minute and second of the timestamp was being provided or
--          the current time if not.
-- @usage
-- local unpack_timestamp
--       = import 'lua-nucleo/timestamp.lua'
--       {
--         'unpack_timestamp'
--       }
--
-- local push_date = function(year, month, day, hour, minute, second)
--   -- do something
-- end
--
-- push_date(unpack_timestamp())
local unpack_timestamp = function(timestamp)
  timestamp = timestamp or os_time()

  local t = os.date("*t", timestamp)

  return t.year, t.month, t.day, t.hour, t.min, t.sec
end

--- Parses the input string according to datetime format. Calculates a
-- Unit/POSIX timestamp using parsed values.
-- @tparam string str A string to be parsed.
-- @tparam[opt=<code>"^(%d%d)%.(%d%d)%.(%d%d%d%d) (%d%d):(%d%d):(%d%d)"</code>]
-- string format
-- A format to be used by the parser in a form of the Lua string pattern where
-- first 6 six captures should be defined in the following order:
-- <ul>
-- <li>day of month</li>
-- <li>month number by count</li>
-- <li>four digits year</li>
-- <li>24h format hour</li>
-- <li>minute</li>
-- <li>second</li>
-- </ul>
-- Each of the captures should be parsable to number.
-- @treturn[1] number Resulted timestamp.
-- @treturn[2] nil If parse errors are occurred.
-- @usage
-- local make_timestamp_from_string
--       = import 'lua-nucleo/timestamp.lua'
--       {
--         'make_timestamp_from_string'
--       }
--
-- local time1 = make_timestamp_from_string('04.02.2021 09:18:03')
--
-- local format = '^d=(%d+),m=(%d+),y=(%d+) time="(%d%d):(%d%d):(%d%d)"'
-- local time2 = make_timestamp_from_string(
--     'd=4,m=2,y=2021 time="09:18:03"',
--     format
--   )
local make_timestamp_from_string = function(str, format)
  format = format or "^(%d%d)%.(%d%d)%.(%d%d%d%d) (%d%d):(%d%d):(%d%d)"

  local dom, mon, y, h, m, s = str:match(format)
  if s == nil then
    return nil
  end

  return os.time(make_time_table(
    tonumber(dom),
    tonumber(mon),
    tonumber(y),
    tonumber(h),
    tonumber(m),
    tonumber(s)
  ))
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
  unpack_timestamp = unpack_timestamp;
  make_timestamp_from_string = make_timestamp_from_string;
}
