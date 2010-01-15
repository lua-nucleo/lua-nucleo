-- 0020-args.lua: tests for various utilities related to function arguments
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_fails_with_substring,
      ensure_returns
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring',
        'ensure_returns'
      }

local nargs,
      pack,
      eat_true,
      arguments,
      method_arguments,
      optional_arguments,
      args_exports
      = import 'lua-nucleo/args.lua'
      {
        'nargs',
        'pack',
        'eat_true',
        'arguments',
        'method_arguments',
        'optional_arguments'
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

test:test_for "eat_true" (function()
  ensure_returns("no args", 0, { }, eat_true(true))
  ensure_returns("one arg", 1, { 42 }, eat_true(true, 42))
  ensure_returns(
      "nils",
      4, { nil, nil, "embedded\0zero", nil },
      eat_true(true, nil, nil, "embedded\0zero", nil)
    )

  ensure_fails_with_substring(
      "no args at all",
      function() eat_true() end,
      "can't eat true, got nil"
    )

  ensure_fails_with_substring(
      "false",
      function() eat_true(false) end,
      "can't eat true, got false"
    )

  ensure_fails_with_substring(
      "nil",
      function() eat_true(nil) end,
      "can't eat true, got nil"
    )

  ensure_fails_with_substring(
      "data",
      function() eat_true(42) end,
      "can't eat true, got 42"
    )

  ensure_fails_with_substring(
      "data, string",
      function() eat_true(42, "MYERROR") end,
      "can't eat true, got 42"
    )

  ensure_fails_with_substring(
      "error message",
      function() eat_true(nil, "MYERROR") end,
      "can't eat true:\nMYERROR"
    )

  ensure_fails_with_substring(
      "nil, true",
      function() eat_true(nil, true) end,
      "can't eat true, got nil"
    )
end)

---------------------------------------------------------------------------

do
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

  -- TODO: Generalize copy-paste with below
  local run_arguments_tests = function(arguments, check_arguments, check_arguments_fail)
    local self = {} -- Note only good self is tested

         check_arguments(arguments, "empty", self)
    check_arguments_fail(arguments, "bad type dangling", "arguments: bad call, dangling argument detected", self, "garbage")
    check_arguments_fail(arguments, "bad type", "argument #1: bad expected type `garbage'", self, "garbage", nil)
    check_arguments_fail(arguments, "bad type: false dangling", "arguments: bad call, dangling argument detected", self, false)
    check_arguments_fail(arguments, "bad type: false", "argument #1: bad expected type `false'", self, false, nil)
    check_arguments_fail(arguments, "bad type with value", "argument #1: bad expected type `garbage'", self, "garbage", "value")
         check_arguments(arguments, "nil", self, "nil", nil)
    check_arguments_fail(arguments, "bad type tail dangling", "arguments: bad call, dangling argument detected", self, "nil", nil, "tail garbage")
    check_arguments_fail(arguments, "bad type tail", "argument #2: bad expected type `tail garbage'", self, "nil", nil, "tail garbage", nil)
         check_arguments(arguments, "boolean", self, "boolean", false)
         check_arguments(arguments, "many args", self, "boolean", false, "nil", nil, "number", 42)
    check_arguments_fail(arguments, "bad in the middle", "argument #2: expected `nil', got `number'", self, "boolean", false, "nil", 42, "number", 42)
    check_arguments_fail(arguments, "nil at the end", "argument #2: expected `table', got `nil'", self, "boolean", false, "table", nil)
    check_arguments_fail(arguments, "false at the end fails", "argument #2: expected `table', got `boolean'", self, "boolean", false, "table", false)
    check_arguments_fail(arguments, "bad at the end", "argument #3: expected `number', got `table'", self, "boolean", false, "nil", nil, "number", {})

    do
      local called = false
      local fn = function() called = true end

      check_arguments(arguments, "function", self, "function", fn)
      ensure_equals("function should be not called", called, false)
    end

    do
      local called = false
      local fn = function() called = true end

      check_arguments_fail(arguments, "bad function", "argument #1: expected `number', got `function'", self, "number", fn)
      ensure_equals("function as bad argument should be not called", called, false)
    end

    check_arguments_fail(arguments, "first extra nil", "arguments: bad call, dangling argument detected", self, nil)
    check_arguments_fail(arguments, "second extra nil", "arguments: bad call, dangling argument detected", self, "number", 42, nil)
    check_arguments_fail(arguments, "nil, second extra nil", "arguments: bad call, dangling argument detected", self, "nil", nil, nil)
  end

  test:test_for "arguments" (function()
    run_arguments_tests(
        function(self, ...) return arguments(...) end, -- Filter out self
        check_arguments,
        check_arguments_fail
      )
  end)

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
end

---------------------------------------------------------------------------

do
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

  -- TODO: Generalize copy-paste with above
  local run_optional_arguments_tests = function(arguments, check_arguments, check_arguments_fail)
    local self = {} -- Note only good self is tested

         check_arguments(arguments, "empty", self)
    check_arguments_fail(arguments, "bad type dangling", "arguments: bad call, dangling argument detected", self, "garbage")
    check_arguments_fail(arguments, "bad type", "argument #1: bad expected type `garbage'", self, "garbage", nil)
    check_arguments_fail(arguments, "bad type: false dangling", "arguments: bad call, dangling argument detected", self, false)
    check_arguments_fail(arguments, "bad type: false", "argument #1: bad expected type `false'", self, false, nil)
    check_arguments_fail(arguments, "bad type with value", "argument #1: bad expected type `garbage'", self, "garbage", "value")
         check_arguments(arguments, "nil", self, "nil", nil)
    check_arguments_fail(arguments, "bad type tail dangling", "arguments: bad call, dangling argument detected", self, "nil", nil, "tail garbage")
    check_arguments_fail(arguments, "bad type tail", "argument #2: bad expected type `tail garbage'", self, "nil", nil, "tail garbage", nil)
         check_arguments(arguments, "boolean", self, "boolean", false)
         check_arguments(arguments, "many args", self, "boolean", false, "nil", nil, "number", 42)
    check_arguments_fail(arguments, "bad in the middle", "argument #2: expected `nil', got `number'", self, "boolean", false, "nil", 42, "number", 42)
         check_arguments(arguments, "nil does not fail", self, "boolean", false, "table", nil)
    check_arguments_fail(arguments, "false at the end fails", "argument #2: expected `table', got `boolean'", self, "boolean", false, "table", false)
    check_arguments_fail(arguments, "bad at the end", "argument #3: expected `number', got `table'", self, "boolean", false, "nil", nil, "number", {})

    do
      local called = false
      local fn = function() called = true end

      check_arguments(arguments, "function", self, "function", fn)
      ensure_equals("function should be not called", called, false)
    end

    do
      local called = false
      local fn = function() called = true end

      check_arguments_fail(arguments, "bad function", "argument #1: expected `number', got `function'", self, "number", fn)
      ensure_equals("function as bad argument should be not called", called, false)
    end

    check_arguments_fail(arguments, "first extra nil", "arguments: bad call, dangling argument detected", self, nil)
    check_arguments_fail(arguments, "second extra nil", "arguments: bad call, dangling argument detected", self, "number", 42, nil)
    check_arguments_fail(arguments, "nil, second extra nil", "arguments: bad call, dangling argument detected", self, "nil", nil, nil)
  end

  test:test_for "optional_arguments" (function()
    run_optional_arguments_tests(
        function(self, ...) return optional_arguments(...) end, -- Filter out self
        check_arguments,
        check_arguments_fail
      )
  end)
end

---------------------------------------------------------------------------

assert(test:run())
