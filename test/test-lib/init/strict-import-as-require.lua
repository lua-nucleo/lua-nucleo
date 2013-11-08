--------------------------------------------------------------------------------
--- Test initialization file with import as require
-- @module test.test-lib.init.strict-import-as-require
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

require 'lua-nucleo'

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

return make_suite
