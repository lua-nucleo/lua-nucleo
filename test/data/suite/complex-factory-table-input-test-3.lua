--------------------------------------------------------------------------------
-- complex-factory-table-input-test-3.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite(
    "complex-factory-table-input-test-3",
    {
      some_factory = true,
      other_factory = true
    }
  )

test:factory "some_factory" { "method0", "method1", "method2", "method3" }
test:method "method0" (function() end)
test:method "method1" (function() end)
test:methods "method2" "method3"
