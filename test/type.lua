-- type.lua: tests for Lua type manipulation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
      }

local type_imports = import 'lua-nucleo/type.lua' ()

--------------------------------------------------------------------------------

local test = make_suite("type", type_imports)

--------------------------------------------------------------------------------

test:tests_for 'is_nil'
               'is_number'
               'is_string'
               'is_boolean'
               'is_table'
               'is_function'
               'is_thread'
               'is_userdata'
               'is_coroutine'
               'is_bool'
               'is_self'
               'is_type'

--------------------------------------------------------------------------------

test "all_predicates" (function()
  local is = type_imports
  
  local values =
  {
    -- ["nil"] = nil; -- Can't do nil values in tables.
    ["number"] = 42;
    ["string"] = "lua-nucleo";
    ["boolean"] = false;
    ["table"] = {};
    ["function"] = function() end;
    ["thread"] = coroutine.create(function() end);
    ["userdata"] = newproxy();
  }
  
  assert(is.is_coroutine == is.is_thread)
  assert(is.is_bool == is.is_boolean)
  assert(is.is_self == is.is_table)
  
  assert(is.is_nil(nil) == true)
  
  for name1, value1 in pairs(values) do
    assert(is.is_type(name1) == true)
    assert(is.is_nil(value1) == false)
    for name2, value2 in pairs(values) do
      assert(
          assert(is["is_"..name1])(value2) == (name1 == name2)
        )
    end
  end
end)

--------------------------------------------------------------------------------

assert(test:run())
