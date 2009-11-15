-- functional.lua -- tests for the functional module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure_equals,
      ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure_tequals'
      }

local do_nothing,
      identity,
      invariant,
      create_table,
      make_generator_mt,
      functional_exports =
      import 'lua-nucleo/functional.lua'
      {
        'do_nothing',
        'identity',
        'invariant',
        'create_table',
        'make_generator_mt'
      }

--------------------------------------------------------------------------------

local test = make_suite("functional", functional_exports)

--------------------------------------------------------------------------------

test:test_for "do_nothing" (function()
  do_nothing() -- Just a smoke test
end)

--------------------------------------------------------------------------------

test:test_for "identity" (function()
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

test:test_for "invariant" (function()
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

test:tests_for "make_generator_mt"

--------------------------------------------------------------------------------

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

assert(test:run())
