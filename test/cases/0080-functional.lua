--------------------------------------------------------------------------------
-- 0080-functional.lua: tests for (pseudo-)functional stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local unpack = unpack or table.unpack
local newproxy = newproxy or select(
    2,
    unpack({
        xpcall(require, function() end, 'newproxy')
      })
  )

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure_equals,
      ensure_tequals,
      ensure_tdeepequals,
      ensure_returns,
      ensure_fails_with_substring,
      ensure_is
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure_tequals',
        'ensure_tdeepequals',
        'ensure_returns',
        'ensure_fails_with_substring',
        'ensure_is'
      }

local tstr = import 'lua-nucleo/table.lua' { 'tstr' }

local do_nothing,
      identity,
      less_than,
      invariant,
      create_table,
      make_generator_mt,
      arguments_ignorer,
      list_caller,
      bind_many,
      remove_nil_arguments,
      args_proxy,
      compose,
      compose_many,
      maybe_call,
      functional_exports
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing',
        'identity',
        'less_than',
        'invariant',
        'create_table',
        'make_generator_mt',
        'arguments_ignorer',
        'list_caller',
        'bind_many',
        'remove_nil_arguments',
        'args_proxy',
        'compose',
        'compose_many',
        'maybe_call'
      }

--------------------------------------------------------------------------------

local test = make_suite("functional", functional_exports)

--------------------------------------------------------------------------------

test:test_for "do_nothing" (function()
  do_nothing() -- Just a smoke test
end)

--------------------------------------------------------------------------------

test:test_for("identity"):BROKEN_IF(not newproxy) (function()
  local e_nil,
        e_boolean,
        e_number,
        e_string,
        e_table,
        e_function,
        e_thread,
        e_userdata =
        nil,
        true,
        42,
        "identity",
        { 42 },
        function() end,
        coroutine.create(function() end),
        newproxy()

  local a_nil,
        a_boolean,
        a_number,
        a_string,
        a_table,
        a_function,
        a_thread,
        a_userdata,
        a_nothing =
        identity(
            e_nil,
            e_boolean,
            e_number,
            e_string,
            e_table,
            e_function,
            e_thread,
            e_userdata
          )

  ensure_equals("nil", a_nil, e_nil)
  ensure_equals("boolean", a_boolean, e_boolean)
  ensure_equals("number", a_number, e_number)
  ensure_equals("string", a_string, e_string)
  ensure_equals("table", a_table, e_table) -- Note direct equality
  ensure_equals("function", a_function, e_function)
  ensure_equals("thread", a_thread, e_thread)
  ensure_equals("userdata", a_userdata, e_userdata)

  ensure_equals("no extra args", a_nothing, nil)
end)

--------------------------------------------------------------------------------

test:test_for "less_than" (function()
  ensure_equals("1 less than 2", less_than(1, 2), true)
  ensure_equals("2 not less than 2", less_than(2, 2), false)
  ensure_equals("3 not less than 2", less_than(3, 2), false)
  ensure_equals("'a' less than 'b'", less_than("a", "b"), true)
  ensure_equals("'aa' not less than 'a'", less_than("aa", "a"), false)
end)

test:test_for("invariant"):BROKEN_IF(not newproxy) (function()
  local data =
  {
    n = 8; -- Storing size explicitly due to hole in table.
    nil;
    true;
    42;
    "invariant";
    { 42 };
    function() end;
    coroutine.create(function() end);
    newproxy();
  }

  for i = 1, data.n do
    local inv = invariant(data[i])
    assert(type(inv) == "function")
    ensure_equals(
        "invariant "..type(data[i]),
        inv(),
        data[i]
      )
  end
end)

--------------------------------------------------------------------------------

test:test_for "create_table" (function()
  ensure_tequals("empty", create_table(), { })
  ensure_tequals("nil", create_table(nil), { })
  ensure_tequals("normal", create_table(1, "a"), { 1, "a" })
  ensure_tequals(
      "hole",
      create_table(nil, 1, nil, "a", nil),
      { nil, 1, nil, "a", nil }
    )
end)

--------------------------------------------------------------------------------

test:factory "make_generator_mt" (make_generator_mt, function() end)

--------------------------------------------------------------------------------

test:methods "__index"
test "make_generator_mt-nil" (function()
  local num_calls = 0

  local mt = make_generator_mt(
      function(k)
        num_calls = num_calls + 1
        return nil
      end
    )

  local t = setmetatable({ }, mt)

  ensure_equals("no calls", num_calls, 0)
  ensure_equals("get 42", t[42], nil)
  ensure_equals("one call", num_calls, 1)
  ensure_equals("get A", t["A"], nil)
  ensure_equals("two calls", num_calls, 2)
  ensure_equals("get 42 again", t[42], nil)
  ensure_equals("nill not cached", num_calls, 3)
end)

test "make_generator_mt-echo" (function()
  local num_calls = 0

  local mt = make_generator_mt(
      function(k)
        num_calls = num_calls + 1
        return k
      end
    )

  local t = setmetatable({ ["A"] = "B" }, mt)

  ensure_equals("no calls", num_calls, 0)
  ensure_equals("get 42", t[42], 42)
  ensure_equals("one call", num_calls, 1)
  ensure_equals("get 42 again", t[42], 42)
  ensure_equals("value cached", num_calls, 1)

  ensure_equals("predefined value", t["A"], "B")
  ensure_equals("still one call", num_calls, 1)

  local k = {}
  ensure_equals("get {}", t[k], k)
  ensure_equals("two calls", num_calls, 2)
  ensure_equals("get {} again", t[k], k)
  ensure_equals("still two calls", num_calls, 2)
end)

--------------------------------------------------------------------------------

test:test_for "arguments_ignorer" (function()
  local fn = function(...)
    ensure_equals("no args", select("#", ...), 0)
    return 1, nil, 2
  end

  ensure_tequals("check", { arguments_ignorer(fn)(3, nil, 4) }, { 1, nil, 2 })
end)

--------------------------------------------------------------------------------

test:group "list_caller"

--------------------------------------------------------------------------------

test "list_caller-empty" (function()
  local caller = list_caller({ })
  caller()
end)

test "list_caller-basic" (function()
  local expected_arguments =
  {
    [1] =
    {
      id = 1;
      { n = 3; 1, nil, 2 };
    };
    [2] =
    {
      id = 2;
      { n = 4, "one", "two", "three", 4 };
    };
    [3] =
    {
      id = 3;
      { n = 0 };
    };
    [4] =
    {
      id = 4;
      { n = 0 };
    };
  }

  local actual_arguments = { }

  local common_fn = function(id)
    return function(...)
      actual_arguments[#actual_arguments + 1] =
      {
        id = id;
        { n = select("#", ...), ... };
      }
    end
  end

  local calls =
  {
    [1] =
    {
      n = expected_arguments[1][1].n;
      common_fn(1);
      unpack(expected_arguments[1][1], 1, expected_arguments[1][1].n);
    };
    [2] =
    {
      -- No explicit n
      common_fn(2);
      unpack(expected_arguments[2][1], 1, expected_arguments[2][1].n);
    };
    [3] =
    {
      n = expected_arguments[3][1].n;
      common_fn(3);
      -- No arguments
    };
    [4] =
    {
      -- No explicit n
      common_fn(4);
      -- No arguments
    };
  }

  local caller = list_caller(calls)

  ensure_tequals("nothing is called yet", actual_arguments, { })

  caller()

  ensure_tdeepequals(
      "all functions are called properly",
      actual_arguments,
      expected_arguments
    )
end)

test "list_caller-nil-arguments" (function()
  local expected_arguments =
  {
    [1] =
    {
      id = 1;
      { n = 3; nil, nil, nil };
    };
    [2] =
    {
      id = 2;
      { n = 4; nil, nil, nil, nil };
    };
  }

  local actual_arguments = { }

  local common_fn = function(id)
    return function(...)
      actual_arguments[#actual_arguments + 1] =
      {
        id = id;
        { n = select("#", ...), ... };
      }
    end
  end

  local calls =
  {
    [1] =
    {
      n = expected_arguments[1][1].n;
      common_fn(1);
      unpack(expected_arguments[1][1], 1, expected_arguments[1][1].n);
    };
    [2] =
    {
      n = expected_arguments[2][1].n;
      common_fn(2);
      unpack(expected_arguments[2][1], 1, expected_arguments[2][1].n);
    };
  }

  local caller = list_caller(calls)

  ensure_tequals("nothing is called yet", actual_arguments, { })

  caller()

  ensure_tdeepequals(
      "all functions are called properly",
      actual_arguments,
      expected_arguments
    )
end)

--------------------------------------------------------------------------------

test:group "bind_many"

--------------------------------------------------------------------------------

test "bind_many-empty-simple" (function()
  local called = false

  local fn = bind_many(function(...)
    ensure_equals("no args", select("#", ...), 0)
    ensure_equals("call once", called, false)
    called = true
  end)

  ensure_equals("call check", fn(), nil)

  ensure_equals("was called", called, true)
end)

test "bind_many-empty-with-return-values" (function()
  local called = false

  local fn = bind_many(function(...)
    ensure_equals("call once", called, false)
    called = true
    return { n = select("#", ...), ... }, ...
  end)

  ensure_equals("not called yet", called, false)

  local res = { fn() }

  ensure_equals("was called", called, true)

  ensure_tdeepequals(
      "return values check",
      res,
      { { n = 0 } }
    )
end)

test "bind_many-basic" (function()
  local called = false

  local fn = bind_many(function(...)
    ensure_equals("call once", called, false)
    called = true
    return { n = select("#", ...), ... }, ...
  end, 1, nil, 2)

  ensure_equals("not called yet", called, false)

  local res = { fn("XXX") }

  ensure_equals("was called", called, true)

  ensure_tdeepequals(
      "return values check",
      res,
      { { n = 3, 1, nil, 2 }, 1, nil, 2 }
    )
end)

test "bind_many-nil-arguments" (function()
  local called = false

  local fn = bind_many(function(...)
    ensure_equals("call once", called, false)
    called = true
    return { n = select("#", ...), ... }, ...
  end, nil, nil, nil, nil, nil)

  ensure_equals("not called yet", called, false)

  local res = { fn("XXX") }

  ensure_equals("was called", called, true)

  ensure_tdeepequals(
      "return values check",
      res,
      { { n = 5, nil, nil, nil, nil, nil }, nil, nil, nil, nil, nil }
    )
end)

--------------------------------------------------------------------------------

test:group "remove_nil_arguments"

--------------------------------------------------------------------------------

test "remove_nil_arguments-empty" (function()
  ensure_returns(
      "empty",
      0, { },
      remove_nil_arguments()
    )
end)

test "remove_nil_arguments-no-nils" (function()
  ensure_returns(
      "empty",
      3, { 1, false, "nil" },
      remove_nil_arguments(1, false, "nil")
    )
end)

test "remove_nil_arguments-some-nils" (function()
  ensure_returns(
      "empty",
      3, { 1, false, "nil" },
      remove_nil_arguments(nil, 1, nil, false, nil, "nil")
    )
end)

test "remove_nil_arguments-all-nils" (function()
  ensure_returns(
      "empty",
      0, { },
      remove_nil_arguments(nil, nil, nil)
    )
end)

--------------------------------------------------------------------------------

test:group "compose"

test:case "compose_positive_test" (function()
  local first = function(x)
    return "one_" .. x
  end

  local second = function(x)
    return "two_" .. x
  end

  local composed = compose(first, second)

  ensure_is("function", composed, "function")
  ensure_returns(
      "composed function works",
      1, { "one_two_three" },
      composed('three')
    )
end)

test:case "compose_negative_test" (function()
  local stub = function() end

  ensure_fails_with_substring(
      "check type mismatch",
      function() compose(stub, 42, stub)() end,
      "`function' expected, got `number'"
    )

  ensure_fails_with_substring(
      "check type mismatch",
      function() compose_many(nil, stub)() end,
      "`function' expected, got `nil'"
    )
end)

--------------------------------------------------------------------------------

test:group "compose_many"

test:case "compose_many_positive_test" (function()
  local called = { }
  local make_func = function(const)
    return function(x)
      called[const] = true
      return const .. x
    end
  end

  local composed = compose_many(make_func("a"), make_func("b"), make_func("c"))
  ensure_is("function", composed, "function")
  ensure_returns(
      "combined function works",
      1, { "abcd" },
      composed('d')
    )
  ensure_tequals(
      "all functions called",
      called,
      {
        ["a"] = true;
        ["b"] = true;
        ["c"] = true;
      }
    )
end)

test:case "compose_many_negative_test" (function()
  local stub = function() end
  ensure_fails_with_substring(
      "check type mismatch",
      function() compose_many(stub, 42, stub)() end,
      "`function' expected, got `number'"
    )
  ensure_fails_with_substring(
      "check type mismatch",
      function() compose_many(stub, nil, stub)() end,
      "`function' expected, got `nil'"
    )
end)

--------------------------------------------------------------------------------

test:test_for "maybe_call" (function()
  local test_string = "string"

  ensure_returns(
      "maybe call not a function",
      1, { test_string },
      maybe_call(test_string)
    )

  local test_function = function(number)
    return number * 2
  end

  ensure_returns(
      "maybe call function",
      1, { 2 },
      maybe_call(test_function, 1)
    )
end)

--------------------------------------------------------------------------------

test:UNTESTED 'args_proxy'
