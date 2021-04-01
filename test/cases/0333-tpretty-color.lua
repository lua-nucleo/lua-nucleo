--------------------------------------------------------------------------------
-- 0333-tpretty-color.lua: tests for pretty-printer in color mode
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

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

local tpretty
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty'
      }

local table_concat = table.concat

--------------------------------------------------------------------------------

local test = make_suite("tpretty-color")

--------------------------------------------------------------------------------

test "test tpretty color simple curly braces" (function ()
  local colors =
  {
    curly_braces = '<~>';
    reset_color = '</>';
  }

  ensure_equals(
      'colorized properly',
      tpretty({}, nil, nil, colors),
      '<~>{ </> <~>}</>'
    )

  local obj =
  {
    { };
    [{ }] = { };
  }
  local expected = '<~>{</>\n'
                .. '  <~>{ </> <~>}</>;\n'
                .. '  [\n'
                .. '  { }] = \n'
                .. '  <~>{ </> <~>}</>;\n'
                .. '<~>}</>'
  local actual = tpretty(obj, nil, nil, colors)

  ensure_equals('colorized properly', actual, expected)
end)

test "test tpretty color simple key" (function ()
  local colors =
  {
    key = '<key>';
    reset_color = '</>';
  }

  local obj =
  {
    { field = 123 };
    { [{ field = 456 }] = 789 };
    { [555] = 777 };
    { [true] = false };
  }

  local expected = [[{
  { <key>field</> = 123 };
  {
    <key>[
    { field = 456 }]</> = 789;
  };
  { <key>[555]</> = 777 };
  { <key>[true]</> = false };
}]]

  local actual = tpretty(obj, nil, nil, colors)

  ensure_equals('colorized properly', actual, expected)
end)

test "test tpretty color simple boolean" (function ()
  local colors =
  {
    boolean = '<bool>';
    reset_color = '</>';
  }

  local obj =
  {
    true;
    false;
    { [true] = 123 };
    { [{ true, false }] = { false, true } };
    { [{ [true] = false }] = 'str' };
  }

  local expected = [[{
  <bool>true</>;
  <bool>false</>;
  { [true] = 123 };
  {
    [
    { true, false }] = { <bool>false</>, <bool>true</> };
  };
  {
    [
    { [true] = false }] = "str";
  };
}]]

  local actual = tpretty(obj, nil, nil, colors)

  ensure_equals('colorized properly', actual, expected)
end)
