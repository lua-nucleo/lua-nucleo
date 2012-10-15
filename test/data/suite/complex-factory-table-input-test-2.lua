--------------------------------------------------------------------------------
-- complex-factory-table-input-test-2.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite(
    "complex-factory-table-input-test-2",
    {
      some_factory = true,
      other_factory = true
    }
  )

test:factory "some_factory" { "method0", "method1", "method2", "method3" }
test:method "method0" (function() end)
test:method "method1" (function() suite_tests_results = 2 end)
