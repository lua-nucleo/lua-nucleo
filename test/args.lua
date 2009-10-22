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

local check_arguments = function(arguments_fn, name, self, ...)
  -- Note self is ignored
  -- TODO: Use name in error message
  arguments_fn(self, ...)
end

local check_arguments_fail = function(arguments_fn, name, expected_msg, self, ...)
  -- Note self is ignored
  local n, args = pack(...)
  ensure_fails_with_substring(
      name,
      function() arguments_fn(self, unpack(args, 1, n)) end,
      expected_msg
    )
end

local run_arguments_tests = function(arguments, check_arguments, check_arguments_fail)
  local self = {} -- Note only good self is tested

       check_arguments(arguments, "empty", self)
  check_arguments_fail(arguments, "bad type", "argument #1: bad expected type `garbage'", self, "garbage")
  check_arguments_fail(arguments, "bad type: false", "argument #1: bad expected type `false'", self, false)
  check_arguments_fail(arguments, "bad type with value", "argument #1: bad expected type `garbage'", self, "garbage", "value")
       check_arguments(arguments, "nil", self, "nil", nil)
  check_arguments_fail(arguments, "bad type tail", "argument #2: bad expected type `tail garbage'", self, "nil", nil, "tail garbage")
       check_arguments(arguments, "boolean", self, "boolean", false)
       check_arguments(arguments, "many args", self, "boolean", false, "nil", nil, "number", 42)
  check_arguments_fail(arguments, "bad in the middle", "argument #2: expected `nil', got `number'", self, "boolean", false, "nil", 42, "number", 42)
  check_arguments_fail(arguments, "bad at the end", "argument #3: expected `number', got `table'", self, "boolean", false, "nil", nil, "number", {})
end

test:test_for "arguments" (function()
  run_arguments_tests(
      function(self, ...) return arguments(...) end, -- Filter out self
      check_arguments,
      check_arguments_fail
    )
end)

---------------------------------------------------------------------------

test:test_for "method_arguments" (function()
  run_arguments_tests(
      method_arguments,
      check_arguments,
      check_arguments_fail
    )

  -- Additional tests for bad self

  check_arguments_fail(method_arguments, "missing self", "bad self %(got `nil'%); use `:'")
  check_arguments_fail(method_arguments, "missing self, have args", "bad self %(got `string'%); use `:'", "number", 42)
  check_arguments_fail(method_arguments, "missing self, have args", "bad self %(got `nil'%); use `:'", nil, "number", 42)
end)

---------------------------------------------------------------------------

assert(test:run())
