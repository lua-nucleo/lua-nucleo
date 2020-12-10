--------------------------------------------------------------------------------
-- 0290-tstr.lua: tests for visualization of non-recursive tables
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

declare 'jit'
local _VERSION, jit = _VERSION, jit

local table_concat = table.concat
local math_pi = math.pi
local setmetatable = setmetatable
local create_thread = coroutine.create

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

local tdeepequals = import 'lua-nucleo/tdeepequals.lua' { 'tdeepequals' }
local make_concatter = import 'lua-nucleo/string.lua' { 'make_concatter' }

local tstr,
      tstr_cat,
      tstr_exports
      = import 'lua-nucleo/tstr.lua'
      {
        'tstr',
        'tstr_cat'
      }

--------------------------------------------------------------------------------

local test = make_suite("tstr", tstr_exports)

--------------------------------------------------------------------------------

-- Declares a set of tests for given function
local declare_tests = function(tested_fn_name, serialization_fn)

  -- Helpers

  -- checks that value is serialized and deserialized correctly
  local check_deserialization = function(msg, test_value, compare_fn)
    compare_fn = compare_fn or ensure_equals --default compare function
    local serialized = serialization_fn(test_value)
    assert(type(serialized) == 'string', 'tstr produced not a string')
    local deserialized = assert(loadstring('return ' .. serialized))()
    compare_fn(msg .. ": incorrect deserialized value", deserialized, test_value)
    return serialized
  end

  -- general checker
  -- checks serialization and that serialized string is what we expected
  local check_ok = function(msg, test_value, expected_str, compare_fn)
    ensure_strequals(
        msg,
        check_deserialization(msg, test_value, compare_fn),
        expected_str
      )
  end

  -- checker for string data
  local check_str_ok = function(msg, test_value, expected_str)
    check_ok(msg, test_value, expected_str, ensure_strequals)
  end

  -- checker for table data
  local check_tbl_ok = function(msg, test_value, expected_str)
    check_ok(msg, test_value, expected_str, tdeepequals)
  end

  -- Tests

  test:group(tested_fn_name)

  test(tested_fn_name .. "-string") (function ()
    check_str_ok('tstr plain string', 'plain string', '"plain string"')
    check_str_ok('tstr empty string', "", '""')

    local str_with_zero_input = "embedded\0zero"
    local str_with_zero_output = '"embedded\\0zero"'
    if _VERSION == "Lua 5.1" and jit == nil then
      str_with_zero_output = '"embedded\\000zero"'
    end
    check_str_ok('tstr zero symbol', str_with_zero_input, str_with_zero_output)
  end)

  test(tested_fn_name .. "-boolean") (function ()
    check_ok("tstr 'true'", true, "true")
    check_ok("tstr 'false'", false, "false")
  end)

  test(tested_fn_name .. "-nil") (function ()
    check_ok("tstr 'nil'", nil, "nil")
  end)

  test(tested_fn_name .. "-number") (function ()
    check_ok("tstr positive number", 42, "42")
    check_ok("tstr negative number", -42, "-42")
    check_ok("tstr 1", 1, "1")
    check_ok("tstr -1", -1, "-1")
    check_ok("tstr 0", 0, "0")
    check_ok("tstr pi", math_pi, "3.1415926535897931")
    check_ok("tstr positive infinity", 1/0, "1/0")
    check_ok("tstr neganive infinity", -1/0, "-1/0")
  end)

  test(tested_fn_name .. "-nan") (function ()
    -- we cannot compare two NaNs aclually, so we check if both are NaN
    local compare_nan = function (msg, value, expected)
      if value ~= value and expected ~= expected then return true end
      print(msg)
      return false
    end

    check_ok("tstr nan", 0/0, '0/0', compare_nan)
  end)

  test(tested_fn_name .. "-table-standard") (function ()
    local tbl_1 = { "plain string", 42, true }
    check_tbl_ok("tstr table", tbl_1, '{"plain string",42,true}')

    local tbl_2 = { true, "true"}
    check_tbl_ok("tstr table: string vs boolean", tbl_2, '{true,"true"}')

    local tbl_3 = { 42, "42"}
    check_tbl_ok("tstr table: string vs number", tbl_3, '{42,"42"}')

    local tbl_with_gap_in_indices =
    {
      [1] = 1;
      [2] = 2;
      [4] = 4;
    }
    check_tbl_ok(
        "tstr table with gap in indices",
        tbl_with_gap_in_indices,
        '{1,2,[4]=4}'
      )

    local tbl_with_keys =
    {
      ["key_1"] = "plain string";
      ["key_2"] = 42;
      ["key_3"] = true;
    }
    check_tbl_ok(
        "tstr table with keys",
        tbl_with_keys,
        '{key_1="plain string",key_3=true,key_2=42}'
      )

    local tbl_with_nested_tbl =
    {
      { "table 1" },
      "just a string",
      { "table 2", 42 }
    }
    check_tbl_ok(
        "tstr table with nested table",
        tbl_with_nested_tbl,
        '{{"table 1"},"just a string",{"table 2",42}}'
      )
  end)

  test(tested_fn_name .. "-table-special-cases") (function ()
    local tbl_1 = { }
    check_tbl_ok("tstr empty table", tbl_1, '{}')

    local tbl_2 = { }
    tbl_2[tbl_2] = { }
    check_tbl_ok("tstr recurcive table", tbl_2, '{["table (recursive)"]={}}')

    local tbl_3 = { }
    check_tbl_ok("tstr table with empty table", { tbl_3, tbl_3 }, '{{},{}}')

    -- metatable is not serialized
    local tbl_with_metatable = { }
    setmetatable(tbl_with_metatable, { __index = function() return 42 end })
    check_tbl_ok("tstr table with metatable", tbl_with_metatable, '{}')
  end)

  if newproxy then
    test(tested_fn_name .. "-non-serializable") (function ()
      local fn = function() end;
      local thread = create_thread(function() end)
      local userdata = newproxy()
      ensure("tstr function", serialization_fn(fn):find("function:"))
      ensure("tstr thread", serialization_fn(thread):find("thread:"))
      ensure("tstr userdata", serialization_fn(userdata):find("userdata:"))
      assert(
          loadstring('return ' .. serialization_fn(fn)),
          "function deserialization failed"
        )()
      assert(
          loadstring('return ' .. serialization_fn(thread)),
          "thread deserialization failed")()
      assert(
          loadstring('return ' .. serialization_fn(userdata)),
          "userdata deserialization failed")()
    end)

    test(tested_fn_name .. "-table-with-non-serializable-values") (function ()
      local fn = function() end;
      local thread = create_thread(function() end)
      local userdata = newproxy()
      local tbl = { fn, thread, userdata }
      check_deserialization(
          "tstr table with non-serializable values: deserialization",
          tbl,
          tdeepequals
        )
    end)

    test(tested_fn_name .. "-table-with-non-serializable-keys") (function ()
      local fn = function() end;
      local thread = create_thread(function() end)
      local userdata = newproxy()
      local tbl = { }
      tbl[fn] = { 1 }
      tbl[thread] = { 2 }
      tbl[userdata] = { 3 }
      check_deserialization(
          "tstr table with non-serializable keys: deserialization",
          tbl,
          tdeepequals
        )
    end)
  else
    test:BROKEN(tested_fn_name .. "-non-serializable")
    test:BROKEN(tested_fn_name .. "-table-with-non-serializable-values")
    test:BROKEN(tested_fn_name .. "-table-with-non-serializable-keys")
  end
  -- Test based on real bug scenario
  -- #3836
  test(tested_fn_name .. "-serialize-inf-bug") (function ()
    local table_with_inf = { 1/0, -1/0, 0/0 }
    check_tbl_ok("table with inf", table_with_inf, "{1/0,-1/0,0/0}")
  end)

end
--------------------------------------------------------------------------------

declare_tests("tstr", tstr) -- tests fot tstr

local custom_serialization_fn = function(value)
  local cat, concat = make_concatter()
  tstr_cat(cat, value)
  return concat()
end
declare_tests("tstr_cat", custom_serialization_fn) -- tests fot tstr_cat
