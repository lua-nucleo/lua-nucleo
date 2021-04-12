--------------------------------------------------------------------------------
-- 0333-tpretty-color.lua: tests for pretty-printer in color mode
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure_equals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure_fails_with_substring'
      }

local tpretty
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty'
      }

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

test "test tpretty color simple string" (function ()
  local colors =
  {
    string = '<str>';
    reset_color = '</>';
  }

  local obj =
  {
    'str1';
    'str2';
    { a = 'str3' };
    { ['str 4'] = 'str5' };
  }

  local expected = [[{
  <str>"str1"</>;
  <str>"str2"</>;
  { a = <str>"str3"</> };
  { ["str 4"] = <str>"str5"</> };
}]]

  local actual = tpretty(obj, nil, nil, colors)

  ensure_equals('colorized properly', actual, expected)
end)

test "test tpretty color simple number" (function ()
  local colors =
  {
    number = '<num>';
    reset_color = '</>';
  }

  local obj =
  {
    123;
    456;
    [789] = 12;
  }

  local expected = '{ <num>123</>, <num>456</>, [789] = <num>12</> }'
  local actual = tpretty(obj, nil, nil, colors)
  ensure_equals('colorized properly', actual, expected)
end)

test "test tpretty color complex" (function ()
  local colors =
  {
    curly_braces = '<~>';
    key = '<key>';
    boolean = '<bool>';
    string = '<str>';
    number = '<num>';
    reset_color = '</>';
  }

  local obj = {
    { };
    456;
    'str1';
    true;
    false;
    { [{ }] = { } } ;
    { field = 123 };
    { [{ field = 456 }] = 789 };
    { [555] = 777 };
    { [true] = false };
    { [true] = 123 };
    { [{ true, false }] = { false, true } };
    { [{ [true] = false }] = 'str' };
    { a = 'str3' };
    { ['str 4'] = 'str5' };
    [789] = 12;
  }

  local expected = [[<~>{</>
  <~>{ </> <~>}</>;
  <num>456</>;
  <str>"str1"</>;
  <bool>true</>;
  <bool>false</>;
  <~>{</>
    <key>[
    { }]</> =]] .. ' \n' .. [[
    <~>{ </> <~>}</>;
  <~>}</>;
  <~>{ </><key>field</> = <num>123</> <~>}</>;
  <~>{</>
    <key>[
    { field = 456 }]</> = <num>789</>;
  <~>}</>;
  <~>{ </><key>[555]</> = <num>777</> <~>}</>;
  <~>{ </><key>[true]</> = <bool>false</> <~>}</>;
  <~>{ </><key>[true]</> = <num>123</> <~>}</>;
  <~>{</>
    <key>[
    { true, false }]</> =]] .. ' \n' .. [[
    <~>{ </><bool>false</>, <bool>true</> <~>}</>;
  <~>}</>;
  <~>{</>
    <key>[
    { [true] = false }]</> = <str>"str"</>;
  <~>}</>;
  <~>{ </><key>a</> = <str>"str3"</> <~>}</>;
  <~>{ </><key>["str 4"]</> = <str>"str5"</> <~>}</>;
  <key>[789]</> = <num>12</>;
<~>}</>]]

  local actual = tpretty(obj, nil, nil, colors)

  ensure_equals('colorized properly', actual, expected)
end)

test "test tpretty color simple lack of reset_color" (function ()
  local colors =
  {
    curly_braces = '<~>';
  }

  ensure_fails_with_substring(
      'lack of reset color error',
      function()
        return tpretty({ }, nil, nil, colors)
      end,
      'the reset color must be defined'
    )
end)
