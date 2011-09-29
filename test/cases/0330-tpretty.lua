-- 0330-tpretty.lua: tests for pretty-printer
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
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

test "tpretty-not-a-table" (function()
  ensure_strequals(
      "t is not a table",
      tpretty(42),
      '42'
    )
end)

test "tpretty-without-optional-params" (function()
  -- TODO: Improve looks.
  local s1 = [[
{
  result = {
    stats = {
      {
        garden = {
          views_total = "INTEGER";
          unique_visits_total = "INTEGER";
          id = "GARDEN_ID";
          views_yesterday = "INTEGER";
          unique_visits_yesterday = "INTEGER";
        };
      };
    };
  };
  events = {};
}]]

  ensure_strequals(
      [[defaul values for optional params is 80 and "  "]],
      tpretty(assert(loadstring("return " .. s1))()),
      tpretty(
          assert(loadstring("return " .. s1))(),
          "  ",
          80
        )
    )
end)

test:TODO "Add test for default string lenght (80)"

--------------------------------------------------------------------------------

test:UNTESTED "tpretty"

--------------------------------------------------------------------------------

-- Based on actual bug scenario
test "tpretty-bug-concat-nil-minimal" (function()
  -- TODO: Improve looks.
  local s1 = [[
{
  stats = {};
}]]

  -- TODO: Improve looks.
  local s2 = [[{}]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty(
              assert(loadstring("return " .. s1))(),
              "  ",
              80
            )
        ),
      s1
    )
-- [[
  ensure_strequals(
      "second result matches expected",
      ensure(
          "render second",
          tpretty(
              assert(loadstring("return " .. s2))(),
              "  ",
              80
            )
        ),
      s2
    )--]]
end)

-- Based on actual bug scenario
test "tpretty-bug-concat-nil-full" (function()
  -- TODO: Improve looks.
  local s1 = [[
{
  result = {
    stats = {
      {
        garden = {
          views_total = "INTEGER";
          unique_visits_total = "INTEGER";
          id = "GARDEN_ID";
          views_yesterday = "INTEGER";
          unique_visits_yesterday = "INTEGER";
        };
      };
    };
  };
  events = {};
}]]

  -- TODO: Improve looks. Should be
--[[
{
  result =
  {
    money_real = "MONEY_REAL";
    money_referral = "MONEY_REFERRAL";
    money_game = "MONEY_GAME";
  };
  events = { };
}--]]

  local s2 = [[
{
  result = {
    money_real = "MONEY_REAL";
    money_referral = "MONEY_REFERRAL";
    money_game = "MONEY_GAME";
  };
  events = {};
}]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty(
              assert(loadstring("return " .. s1))(),
              "  ",
              80
            )
        ),
      s1
    )

  ensure_strequals(
      "second result matches expected",
      ensure(
          "render second",
          tpretty(
              assert(loadstring("return " .. s2))(),
              "  ",
              80
            )
        ),
      s2
    )
end)

--------------------------------------------------------------------------------

assert(test:run())
