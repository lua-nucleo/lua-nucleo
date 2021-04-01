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

test "test tpretty color simple boolean" (function ()
  local colors =
  {
    boolean = '[bool]';
    --key = '[key]';
    --curly_braces = '[~]';
    --brackets = '[L]';
    --string = '[str]';
    --number = '[num]';
    --nil_value = '[nil]';
    reset_color = '[/]';
  }

  local ar = {[true] = false}
  local obj =
  {
    true;
    false;
    [true] = 123;
    [{true, false}] = {false, true};
    [ar] = '???';
  }

  --print(tpretty(obj, nil, nil, nil))
  print(tpretty(obj, '--->', 120, colors))
end)
