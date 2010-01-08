-- suite.lua: a simple test suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

do
  local test = make_suite("test", {some_factory = true})
  local var = 1
  test:factory "some_factory" {"method1", "method2", "method3"}

  assert(test:run() == false)
  test:method "method1" (function()
    var = 2
  end)
  assert(test:run() == false)
  assert(var == 2)
  test:methods "method2"
               "method3"
  assert(test:run() == true)
end
