--------------------------------------------------------------------------------
--- Date and time related utilities
-- @module lua-nucleo.datetime-utils
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local os_time, os_date = os.time, os.date

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

--------------------------------------------------------------------------------

--- Converts function arguments to the associative array table and returns it.
-- @tparam number dom A day of a month.
-- @tparam number mon Month number by count.
-- @tparam number y Year.
-- @tparam number h Hour.
-- @tparam number m Minute.
-- @tparam number s Second.
-- @treturn table <code>{
--    day = dom;
--    month = mon;
--    year = y;
--    hour = h;
--    min = m;
--    sec = s;
--  }</code>
local make_time_table = function(dom, mon, y, h, m, s)
  arguments(
      "number", dom,
      "number", mon,
      "number", y,
      "number", h,
      "number", m,
      "number", s
    )

  return
  {
    day = dom;
    month = mon;
    year = y;
    hour = h;
    min = m;
    sec = s;
  }
end

--- Returns number of days in the given month of the given year.
-- (From http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample)
-- @tparam number year Year.
-- @tparam number month Month number by count.
-- @treturn number Number of days in the given month of the given year.
local get_days_in_month = function(year, month)
  arguments(
      "number", year,
      "number", month
    )

  local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  local d = days_in_month[month]

  -- check for leap year
  if month == 2 then
    if year % 4 == 0 then
     if year % 100 == 0 then
      if year % 400 == 0 then
          d = 29
      end
     else
      d = 29
     end
    end
  end

  return d
end

--- Returns a day of a week for the given timestamp.
-- (From http://richard.warburton.it)
-- @tparam number timestamp Unix/POSIX time.
-- @treturn number Day of week, where zero is Sunday.
local get_day_of_week = function(timestamp)
  arguments(
      "number", timestamp
    )
  return os.date('*t',timestamp)['wday'] - 1
end

local day_of_week_name_to_number, month_name_to_number
do
  local months =
  {
    ["1"] = 1; ["2"] = 2; ["3"] = 3; ["4"] = 4; ["5"] = 5; ["6"] = 6;
    ["7"] = 7; ["8"] = 8; ["9"] = 9; ["10"] = 10; ["11"] = 11; ["12"] = 12;
    --
    ["january"]   =  1;
    ["february"]  =  2;
    ["march"]     =  3;
    ["april"]     =  4;
    ["may"]       =  5;
    ["june"]      =  6;
    ["july"]      =  7;
    ["august"]    =  8;
    ["september"] =  9;
    ["october"]   = 10;
    ["november"]  = 11;
    ["december"]  = 12;
    -- guffy names
    ["jan"] = 1; ["feb"] = 2; ["mar"] = 3; ["apr"] = 4; ["may"] = 5; ["jun"] = 6;
    ["jul"] = 7; ["aug"] = 8; ["sep"] = 9; ["oct"] = 10; ["nov"] = 11; ["dec"] = 12;
  }

  local days_of_week =
  {
    ["0"] = 0; ["1"] = 1; ["2"] = 2; ["3"] = 3; ["4"] = 4; ["5"] = 5; ["6"] = 6;
    --
    ["sunday"]    = 0;
    ["monday"]    = 1;
    ["tuesday"]   = 2;
    ["wednesday"] = 3;
    ["thursday"]  = 4;
    ["friday"]    = 5;
    ["saturday"]  = 6;
    -- guffy names
    ["sun"] = 0;
    ["mon"] = 1;
    ["tue"] = 2;
    ["wed"] = 3;
    ["thu"] = 4;
    ["fri"] = 5;
    ["sat"] = 6;
  }

  --- Converts the given string to a day of a week.
  -- @tparam string v Day of week string representation.
  -- @treturn number Day of week, where zero is Sunday.
  -- @local
  day_of_week_name_to_number = function(v)
    arguments(
        "string", v
      )
    return days_of_week[v:lower()]
  end

  --- Converts the given string to a month number.
  -- @tparam string v Month string representation.
  -- @treturn number Month number by count.
  -- @local
  month_name_to_number = function(v)
    arguments(
        "string", v
      )
    return months[v:lower()]
  end
end

--------------------------------------------------------------------------------

return
{
  make_time_table = make_time_table;
  get_days_in_month = get_days_in_month;
  get_day_of_week = get_day_of_week;
  day_of_week_name_to_number = day_of_week_name_to_number;
  month_name_to_number = month_name_to_number;
}
