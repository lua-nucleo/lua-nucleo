-- factory.lua -- tests for the factory module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local common_method_list,
      factory_exports =
      import 'lua-nucleo/factory.lua'
      {
        'common_method_list'
      }

--------------------------------------------------------------------------------

local test = make_suite("functional", factory_exports)

--------------------------------------------------------------------------------

test:UNTESTED "common_method_list"

--------------------------------------------------------------------------------

assert(test:run())
