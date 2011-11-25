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

test:UNTESTED "tpretty"

---------------------------------------------------------------------------------

test "tpretty-not-a-table" (function()
  ensure_strequals(
      "t is not a table",
      tpretty(42),
      '42'
    )
end)

test "tpretty-simple-table" (function()
  ensure_strequals(
      "t is a simple table",
      tpretty({"DEPLOY_MACHINE"}),
      '{ "DEPLOY_MACHINE" }'
    )
end)

test "tpretty-without-optional-params" (function()
  local s1 = [[
{
  result =
  {
    stats =
    {
      {
        garden =
       {
          views_total = "INTEGER";
          unique_visits_total = "INTEGER";
          id = "GARDEN_ID";
          views_yesterday = "INTEGER";
          unique_visits_yesterday = "INTEGER";
        };
      };
    };
  };
  events = { };
}]]

  ensure_strequals(
      [[default values for optional params is 80 and "  "]],
      tpretty(ensure("parse", (loadstring("return " .. s1))())),
      tpretty(
          ensure("parse", loadstring("return " .. s1))(),
          "  ",
          80
        )
    )
end)

-- Based on actual bug scenario
test "tpretty-bug-concat-nil-minimal" (function()
  local s1 = [[
{
  stats = { };
}]]

  local s2 = [[{ }]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty(
              ensure("parse", loadstring("return " .. s1))(),
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
              ensure("parse", loadstring("return " .. s2))(),
              "  ",
              80
            )
        ),
      s2
    )--]]
end)

-- Based on actual bug scenario
test "tpretty-bug-concat-nil-full" (function()
  local s1 = [[
{
  result =
  {
    stats =
    {
      garden =
      {
        views_total = "INTEGER";
        unique_visits_total = "INTEGER";
        id = "GARDEN_ID";
        views_yesterday = "INTEGER";
        unique_visits_yesterday = "INTEGER";
      };
    };
  };
  events = { };
}]]

  local s2 = [[
{
  result =
  {
    money_real = "MONEY_REAL";
    money_referral = "MONEY_REFERRAL";
    money_game = "MONEY_GAME";
  };
  events = { };
}]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty(
              ensure("parse", loadstring("return " .. s1))(),
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
              ensure("parse", loadstring("return " .. s2))(),
              "  ",
              80
            )
        ),
      s2
    )
end)

-- Test based on real bug scenario
-- #2304 and #2317
--
-- In case of failure. `this_field_was_empty' miss in output
test "tpretty-fieldname-bug" (function ()
  local cache_file_contents = [[
{
  projects =
  {
    ["lua-nucleo"] =
    {
      clusters =
      {
        ["localhost-an"] =
        {
          machines =
          {
            localhost = { this_field_was_empty = true };
          };
        };
      };
    };
  };
}]]
  ensure_strequals(
    "second result matches expected",
    ensure(
      "render second",
      tpretty(
        ensure("parse error", loadstring("return " .. cache_file_contents))(),
        "  ",
        80
       )
    ),
    cache_file_contents
  )
end)

--------------------------------------------------------------------------------

assert(test:run())
