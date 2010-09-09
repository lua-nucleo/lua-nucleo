-- 0340-import_as_require.lua: tests for import-as-require
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

assert(
    loadfile('test/test-lib/init/no-suite-no-import.lua')
  )(...)

--------------------------------------------------------------------------------

package.path = './?' .. package.path

-- Note global!
import = require('lua-nucleo.import_as_require').import

local res, err = pcall(function()
  local test_import = assert(
      assert(assert(loadfile("test/test-lib/import.lua"))())["test_import"]
    )

  test_import("test/data/")
end)

import = nil -- Avoiding side-effects

assert(res, err)
