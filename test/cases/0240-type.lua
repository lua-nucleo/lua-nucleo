--------------------------------------------------------------------------------
-- 0240-type.lua: tests for Lua type manipulation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local unpack = unpack or table.unpack
local newproxy = newproxy or select(
    2,
    unpack({
        xpcall(require, function() end,'newproxy')
      })
  )

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

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
               'is_self'
               'is_type'

--------------------------------------------------------------------------------

if newproxy then
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

    assert(is.is_self == is.is_table)

    assert(is.is_nil(nil) == true)

    assert(is.is_type(42) == false)
    assert(is.is_type("") == false)

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
else
  test:BROKEN "all_predicates"
end
