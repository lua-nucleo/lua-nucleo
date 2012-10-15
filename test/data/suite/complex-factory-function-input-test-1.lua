--------------------------------------------------------------------------------
-- complex-factory-function-input-test-1.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

local make_some = function()
  return
  {
    method1 = 5,
    method2 = "",
    method3 = { }
  }
end

local make_another = function(a, b, c)
  assert(type(a) == "number", "a is number")
  assert(type(b) == "string", "b is string")
  assert(type(c) == "table",  "c is table")
  local method1 = function() end
  local method2 = function() end
  local method3 = function() end
  return
  {
    method1 = method1,
    method2 = method2,
    method3 = method3
  }
end

local test = make_suite(
    "complex-factory-function-input-test-1",
    {
      make_some = true,
      make_another = true
    }
  )

test:factory "make_another" (make_another, 1, "", { })
