-- suite.lua: a simple test suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local assert_is_number,
      assert_is_string,
      assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_string',
        'assert_is_table'
      }

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

--------------------------------------------------------------------------------

local make_another_factory = function(a, b, c)
  assert_is_number(a)
  assert_is_string(b)
  assert_is_table(c)
  local method1 = function()
  end
  local method2 = function()
  end
  local method3 = function()
  end
  return
  {
    method1 = method1,
    method2 = method2,
    method3 = method3
  }
end

--------------------------------------------------------------------------------

local test = make_suite(
    "test",
    {
      some_factory = true
    }
  )
local var = 1
test:factory "some_factory" { "method1", "method2", "method3" }

ensure_equals("test:run()", test:run(), false)
test:method "method1" (function()
  var = 2
end)
ensure_equals("test:run()", test:run(), false)
ensure_equals("var == 2", var, 2)
test:methods "method2"
             "method3"
ensure_equals("test:run()", test:run(), true)

local test = make_suite(
    "test",
    {
      make_another_factory = true
    }
  )
test:factory "make_another_factory" (make_another_factory, 1, "", {})

ensure_equals("test:run()", test:run(), false)
test:method "method1" (function()
  var = var + 2
end)
ensure_equals("test:run()", test:run(), false)
ensure_equals("var", var, 4)
test:methods "method2"
             "method3"
ensure_equals("test:run()", test:run(), true)
