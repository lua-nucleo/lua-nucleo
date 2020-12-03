--------------------------------------------------------------------------------
-- 0330-tpretty.lua: tests for pretty-printer
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local pairs = pairs

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

declare 'jit'
local jit = jit

local loadstring
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_strvariant,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_strvariant',
        'ensure_fails_with_substring'
      }

local tpretty_ex,
      tpretty,
      tpretty_ordered,
      tpretty_exports
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty_ex',
        'tpretty',
        'tpretty_ordered'
      }

local tifindallpermutations
      = import 'lua-nucleo/table-utils.lua'
      {
        'tifindallpermutations'
      }

--------------------------------------------------------------------------------

local test = make_suite("tpretty", tpretty_exports)

--------------------------------------------------------------------------------

test:group "tpretty_ex"

--------------------------------------------------------------------------------

test "tpretty_ex-not-a-table" (function()
  ensure_strequals(
      "t is not a table",
      tpretty_ex(pairs, 42),
      '42'
    )
end)

test "tpretty_ex-simple-table" (function()
  ensure_strequals(
      "t is a simple table",
      tpretty_ex(pairs, {"DEPLOY_MACHINE"}),
      '{ "DEPLOY_MACHINE" }'
    )
end)

test "tpretty_ex-without-optional-params" (function()
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
      tpretty_ex(pairs, ensure("parse", (loadstring("return " .. s1))())),
      tpretty_ex(
          pairs,
          ensure("parse", loadstring("return " .. s1))(),
          "  ",
          80
        )
    )
end)

-- Based on actual bug scenario
test "tpretty_ex-bug-concat-nil-minimal" (function()
  local s1 = [[
{
  stats = { };
}]]

  local s2 = [[{ }]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty_ex(
              pairs,
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
          tpretty_ex(
              pairs,
              ensure("parse", loadstring("return " .. s2))(),
              "  ",
              80
            )
        ),
      s2
    )--]]
end)

-- Based on actual bug scenario
test "tpretty_ex-bug-concat-nil-full" (function()
  -- TODO: systematic solution required
  -- https://github.com/lua-nucleo/lua-nucleo/issues/18

  local garden_fields =
  {
    'views_total = "INTEGER";\n';
    'unique_visits_total = "INTEGER";\n';
    'id = "GARDEN_ID";\n';
    'views_yesterday = "INTEGER";\n';
    'unique_visits_yesterday = "INTEGER";\n';
  }
  local garden_field_permutations = { }
  tifindallpermutations(garden_fields, garden_field_permutations)

  local result_permutations = { }
  for i = 1, #garden_field_permutations do
    local p = garden_field_permutations[i]
    result_permutations[#result_permutations + 1] =
[[  result =
  {
    stats =
    {
      garden =
      {
        ]] .. p[1] .. [[
        ]] .. p[2] .. [[
        ]] .. p[3] .. [[
        ]] .. p[4] .. [[
        ]] .. p[5] .. [[
      };
    };
  };
]]
  end

  local expected_variants = { }
  for i = 1, #result_permutations do
    expected_variants[#expected_variants + 1] = [[
{
]] .. result_permutations[i] .. [[
  events = { };
}]]
    expected_variants[#expected_variants + 1] = [[
{
  events = { };
]] .. result_permutations[i] .. [[
}]]
  end

  ensure_strvariant(
      "first result matches expected",
      ensure(
          "render first",
          tpretty_ex(
              pairs,
              ensure("parse", loadstring("return " .. expected_variants[1]))(),
              "  ",
              80
            )
        ),
      expected_variants
    )

  ------------------------------------------------------------------------------

  local result_fields =
  {
    'money_real = "MONEY_REAL";\n';
    'money_referral = "MONEY_REFERRAL";\n';
    'money_game = "MONEY_GAME";\n';
  }
  local result_field_permutations = { }
  tifindallpermutations(result_fields, result_field_permutations)

  result_permutations = { }
  for i = 1, #result_field_permutations do
    local p = result_field_permutations[i]
    result_permutations[#result_permutations + 1] =
[[  result =
  {
    ]] .. p[1] .. [[
    ]] .. p[2] .. [[
    ]] .. p[3] .. [[
  };
]]
  end

  expected_variants = { }
  for i = 1, #result_permutations do
    expected_variants[#expected_variants + 1] = [[
{
]] .. result_permutations[i] .. [[
  events = { };
}]]
    expected_variants[#expected_variants + 1] = [[
{
  events = { };
]] .. result_permutations[i] .. [[
}]]
  end

  ensure_strvariant(
      "first result matches expected",
      ensure(
          "render first",
          tpretty_ex(
              pairs,
              ensure("parse", loadstring("return " .. expected_variants[1]))(),
              "  ",
              80
            )
        ),
      expected_variants
    )
end)

-- Test based on real bug scenario
-- #2304 and #2317
--
-- In case of failure. `this_field_was_empty' miss in output
test "tpretty_ex-fieldname-bug" (function ()
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
      tpretty_ex(
        pairs,
        ensure("parse error", loadstring("return " .. cache_file_contents))(),
        "  ",
        80
       )
    ),
    cache_file_contents
  )
end)

--------------------------------------------------------------------------------

-- Test based on real bug scenario
-- #3067
--
-- Extra = is rendered as a table separator instead of ;
-- and after opening {.
test "tpretty_ex-wrong-table-list-separator-bug" (function ()
  local data = [[
{
  {
    {
      { };
    };
    {
      { };
    };
  };
}]]
  ensure_strequals(
    "second result matches expected",
    ensure(
      "render second",
      tpretty_ex(
        pairs,
        ensure("data string loads", loadstring("return " .. data))(),
        "  ",
        80
       )
    ),
    data
  )
end)

test "tpretty_ex-wrong-key-indent-bug" (function ()
  local data = [[
{
  { };
  foo =
  {
    { };
  };
}]]
  ensure_strequals(
    "second result matches expected",
    ensure(
      "render second",
      tpretty_ex(
        pairs,
        ensure("data string loads", loadstring("return " .. data))(),
        "  ",
        80
       )
    ),
    data
  )
end)

--------------------------------------------------------------------------------

-- Test based on real bug scenario
-- #3836
test "tpretty_ex-serialize-inf-bug" (function ()
  local table_with_inf = "{ 1/0, -1/0, 0/0 }"

  ensure_strequals(
    "second result matches expected",
    ensure(
      "render second",
      tpretty_ex(
        pairs,
        ensure("parse error", loadstring("return " .. table_with_inf))(),
        "  ",
        80
       )
    ),
    table_with_inf
  )
end)

--------------------------------------------------------------------------------

test "tpretty_ex-custom-iterator" (function()
  local t = { 1, 2, 3 }
  local iterator_invocations_counter = 0

  local custom_iterator = function(table)
    local iterator_function = function(table, pos)
      iterator_invocations_counter = iterator_invocations_counter + 1

      pos = pos or 0
      if pos < #table then
        pos = pos + 1
        return pos, table[pos]
      end
    end
    return iterator_function, table, nil
  end

  tpretty_ex(custom_iterator, t)

  ensure_equals(
      "iterator invocations counter must match expected",
      iterator_invocations_counter,
      4
    )
end)

--------------------------------------------------------------------------------

test:group "tpretty"

--------------------------------------------------------------------------------

test "tpretty-simple" (function()
  local input = [[
{
  1;
  2;
  3;
  a =
  {
    b =
    {
      c = { };
    };
  };
}]]

  ensure_strequals(
    "result matches expected",
    ensure(
      "render is OK",
      tpretty(ensure("parse error", loadstring("return " .. input))())
    ),
    input
  )
end)

--------------------------------------------------------------------------------

test:group "tpretty_ordered"

--------------------------------------------------------------------------------

test "tpretty-ordered" (function()
  local input = [[
{
  result =
  {
    stats2 =
    {
      a3333333333333 = "INTEGER";
      a2222222222222 = "INTEGER";
      a1111111111111 = "GARDEN_ID";
    };
    stats1 =
    {
      bbbbbbbbbbbbbb = "INTEGER";
      cccccccccccccc = "INTEGER";
      aaaaaaaaaaaaaa = "GARDEN_ID";
    };
  };
}]]

  local expected = [[
{
  result =
  {
    stats1 =
    {
      aaaaaaaaaaaaaa = "GARDEN_ID";
      bbbbbbbbbbbbbb = "INTEGER";
      cccccccccccccc = "INTEGER";
    };
    stats2 =
    {
      a1111111111111 = "GARDEN_ID";
      a2222222222222 = "INTEGER";
      a3333333333333 = "INTEGER";
    };
  };
}]]

  ensure_strequals(
      "first result matches expected",
      ensure(
          "render first",
          tpretty_ordered(
              ensure("parse", loadstring("return " .. input))(),
              "  ",
              80
            )
        ),
      expected
    )
end)
