-- args.lua: tests for various utilities related to function arguments
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure,
      ensure_equals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring'
      }

local nargs,
      pack,
      arguments,
      method_arguments,
      args_exports
      = import 'lua-nucleo/args.lua'
      {
        'nargs',
        'pack',
        'arguments',
        'method_arguments'
      }

-------------------------------------------------------------------------

local test = make_suite("args", args_exports)

-------------------------------------------------------------------------

test:test_for "nargs" (function()
  local t1 = "a"
  local t2 = "b"
  local t3 = "c"
  ensure_equals("args number", nargs(t1, t2, t3),3)
  ensure_equals("args number", nargs(t1, nil, t3),3)
  ensure_equals("args number", table.concat({nargs(t1, t2, t3)}), "3abc")
end)

--------------------------------------------------------------------------

test:test_for "pack" (function()
  local t1 = "a"
  local t2 = "b"
  local t3 = "c"
  ensure_equals("args number", pack(t1, t2, t3), 3)
  ensure_equals("args number", pack(t1, nil, t3), 3)
  local num, tbl = pack(t1, t2, t3)
  ensure_equals("args", table.concat(tbl), "abc")
end)

---------------------------------------------------------------------------

test:test_for "arguments" (function()
  local check_arguments = function(name, ...)
    -- TODO: Use name in error message
    arguments(...)
  end

  local check_arguments_fail = function(name, expected_msg, ...)
    local n, args = pack(...)
    ensure_fails_with_substring(
        name,
        function() arguments(unpack(args, 1, n)) end,
        expected_msg
      )
  end

  check_arguments("empty")
  check_arguments_fail("bad type", "argument #1: bad expected type `garbage'", "garbage")
  check_arguments_fail("bad type: false", "argument #1: bad expected type `false'", false)
  check_arguments_fail("bad type with value", "argument #1: bad expected type `garbage'", "garbage", "value")
  check_arguments("nil", "nil", nil)
  check_arguments_fail("bad type tail", "argument #2: bad expected type `tail garbage'", "nil", nil, "tail garbage")
  check_arguments("boolean", "boolean", false)
  check_arguments("many args", "boolean", false, "nil", nil, "number", 42)
  check_arguments_fail("bad in the middle", "argument #2: expected `nil', got `number'", "boolean", false, "nil", 42, "number", 42)
  check_arguments_fail("bad at the end", "argument #3: expected `number', got `table'", "boolean", false, "nil", nil, "number", {})
end)

---------------------------------------------------------------------------

--test:test_for "method_arguments" (function()
--end)

---------------------------------------------------------------------------

assert(test:run())
