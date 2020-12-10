--------------------------------------------------------------------------------
-- typeassert.lua: tests for Lua type assertions
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
      ensure_equals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring'
      }

local typeassert_imports = import 'lua-nucleo/typeassert.lua' ()

--------------------------------------------------------------------------------

local test = make_suite("typeassert", typeassert_imports)

--------------------------------------------------------------------------------

test:UNTESTED 'assert_not_nil'

test:tests_for 'assert_is_nil'
               'assert_is_number'
               'assert_is_string'
               'assert_is_boolean'
               'assert_is_table'
               'assert_is_function'
               'assert_is_thread'
               'assert_is_userdata'
               'assert_is_self'
               'assert_is_type'

--------------------------------------------------------------------------------

if newproxy then
  test "all_assertions" (function()
    local is = typeassert_imports

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

    do
      local self = {}
      ensure_equals("assert_is_self", is.assert_is_self(self), self)

      ensure_fails_with_substring(
          "bad self",
          function() is.assert_is_self(42) end,
          "bad self %(got `number'%); use `:'"
        )
    end

    ensure_equals("assert_is_nil", is.assert_is_nil(nil), nil)

    ensure_fails_with_substring(
        "bad typename type",
        function() is.assert_is_type(42) end,
        "bad typename `42'"
      )

    ensure_fails_with_substring(
        "bad typename value",
        function() is.assert_is_type("") end,
        "bad typename `'"
      )

    for name1, value1 in pairs(values) do
      ensure_equals("assert_is_type", is.assert_is_type(name1), name1)

      ensure_fails_with_substring(
          "not nil",
          function() is.assert_is_nil(value1) end,
          "`nil' expected, got `" .. name1 .. "'"
        )

      for name2, value2 in pairs(values) do
        local fn = assert(is["assert_is_"..name1])
        if name1 == name2 then
          ensure_equals(
              "matching types",
              fn(value2),
              value2
            )
        else
          ensure_fails_with_substring(
              "check type mismatch",
              function() fn(value2) end,
              "`"..name1.."' expected, got `" .. name2 .. "'"
            )
        end
      end
    end
  end)
else
  test:BROKEN "all_assertions"
end
