--------------------------------------------------------------------------------
-- 0070-factory.lua: tests for the factory module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local assert_is_number,
      assert_is_string,
      assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_string',
        'assert_is_table'
      }

local ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_fails_with_substring',
      }

local common_method_list,
      factory_exports =
      import 'lua-nucleo/factory.lua'
      {
        'common_method_list'
      }

--------------------------------------------------------------------------------

local test = make_suite("functional", factory_exports)

--------------------------------------------------------------------------------

test:group "common_method_list"

test "wrong_input" (function()
  local a = {}
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(a, 1, 2, 3) end,
      "argument #1: expected `function', got `table'"
    )
end)

test "wrong_output" (function()
  local a = function() end
  ensure_fails_with_substring(
      "wrong output",
      function() common_method_list(a, 1, 2, 3) end,
      "assertion failed: `table' expected, got `nil'"
    )
end)

local collections_equal = function(list_one, list_two)
  if #list_one ~= #list_two then return false end
  local size = #list_one
  for i = 1, size do
    local is_found = false
    for j = 1, size do
      if list_one[i] == list_two[j] then
        is_found = true
        break
      end
    end
    if is_found == false then return false end
  end
  return true
end

test "no_arguments_no_methods" (function()
  local make_something = function()
    return {}
  end
  local methods_list_true = {}
  local methods_list_test = common_method_list(make_something)
  assert(collections_equal(methods_list_true, methods_list_test))
end)

test "no_arguments_single_method" (function()
  local make_something = function()
    local method_one = function()
      return 1;
    end
    return
    {
      method_one = method_one;
    }
  end
  local methods_list_true = {"method_one"}
  local methods_list_test = common_method_list(make_something)
  assert(collections_equal(methods_list_true, methods_list_test))
end)

test "no_arguments_several_method" (function()
  local make_something = function()
    local method_one = function(a, b, c)
      return a + b + c;
    end
    local method_two = function()
      return 1;
    end
    local method_three = function(a, b, c)
      return a * b - c;
    end
    return
    {
      method_one = method_one;
      method_two = method_two;
      method_three = method_three;
    }
  end
  local methods_list_true =
  {
    "method_one";
    "method_two";
    "method_three";
  }
  local methods_list_test = common_method_list(make_something)
  assert(collections_equal(methods_list_true, methods_list_test))
end)

test "no_arguments_number_key_method" (function()
  local make_something = function()
    local method_one = function(a, b, c)
      return a + b + c;
    end
    local method_two = function()
      return 1;
    end
    local method_three = function(a, b, c)
      return a * b - c;
    end
    return
    {
      method_one;
      [5] = method_two;
      method_three = method_three;
    }
  end
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(make_something) end,
      "string key for function value"
    )
end)

test "no_arguments_table_key_method" (function()
  local make_something = function()
    local method_one = function(a, b, c)
      return a + b + c
    end
    local method_two = function()
      return 1
    end
    local method_three = function(a, b, c)
      return a * b - c
    end
    local k = { method_two = 2 }
    return
    {
      method_one = method_one;
      [k] = method_two;
      method_three = method_three;
    }
  end
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(make_something) end,
      "string key for function value"
    )
end)

test "no_arguments_nested" (function()
  local make_something = function()
    local method_one = function(a, b, c)
      return a + b + c
    end
    local method_two = function()
      return 1
    end
    local method_three = function(a, b, c)
      return a * b - c
    end
    local k = { method_two = 2 }

    local make_inner_something = function()
      local inner_method = function()
        return 1
      end
      return { inner_method = inner_method }
    end
    local inner_table_one = make_inner_something()
    local inner_table_two = make_inner_something()
    return
    {
      inner_table_one = inner_table_one;
      inner_table_two = inner_table_two;
      method_one = method_one;
      method_two = method_two;
      method_three = method_three;
    }
  end
  local methods_list_true =
  {
    "method_one";
    "method_two";
    "method_three";
  }
  local methods_list_test = common_method_list(make_something)
  assert(collections_equal(methods_list_true, methods_list_test))
end)

test "no_arguments_recursive" (function()
  local make_something = function()
    local method_one = function(a, b, c)
      return a + b + c
    end
    local method_two = function()
      return 1
    end
    local method_three = function(a, b, c)
      return a * b - c
    end
    local k = { method_two = 2 }

    local inner_recursive_table = {
      "one";
      "two";
      "three";
    }
    inner_recursive_table[4] = inner_recursive_table

    return
    {
      method_one = method_one;
      method_two = method_two;
      method_three = method_three;
      inner_recursive_table = inner_recursive_table;
    }
  end
  local methods_list_true =
  {
    "method_one";
    "method_two";
    "method_three";
  }
  local methods_list_test = common_method_list(make_something)
  assert(collections_equal(methods_list_true, methods_list_test))
end)

test "several_methods" (function()
  local make_something = function(a, b, c)
    assert_is_number(a)
    assert_is_string(b)
    assert_is_table(c)
    local a_local = a
    local b_local = b
    local c_local = c
    local method_one = function()
      print(b_local)
      return a_local
    end
    local method_two = function()
      return b_local
    end
    local method_three = function(a, b, c)
      return c_local
    end
    local k = { method_two = 2 }
    return
    {
      method_one = method_one;
      method_two = method_two;
      method_three = method_three;
      a_local = a_local;
      b_local = b_local;
      c_local = c_local;
    }
  end
  local methods_list_true =
  {
    "method_one";
    "method_two";
    "method_three";
  }
  local methods_list_test = common_method_list(make_something, 1, "a", {})
  assert(collections_equal(methods_list_true, methods_list_test))
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(make_something, 1, "a") end,
      "`table' expected, got `nil'"
    )
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(make_something, 1) end,
      "`string' expected, got `nil'"
    )
  ensure_fails_with_substring(
      "wrong arguments",
      function() common_method_list(make_something) end,
      "`number' expected, got `nil'"
    )
end)
