-- table.lua: tests for proxy file for various utilities for managing lua tables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- algorithm.lua: tests for various common algorithms
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua/strict.lua')
dofile('lua/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure_equals = import 'lua/ensure.lua' { 'ensure_equals' }

local table_exports = import 'lua/table.lua' ()

--
-- NOTE: Intentionally importing directly from table-utils.lua
--       and doing it after table.lua is loaded. This is done
--       to minimize possible side-effects.
--
local tset, tkeys = import 'lua/table-utils.lua' { 'tset', 'tkeys' }

--------------------------------------------------------------------------------

local test = make_suite("table")

--------------------------------------------------------------------------------

test "ensure-everything-is-exported" (function()
  local table_related_files =
  {
    'lua/table-utils.lua';
    'lua/tdeepequals.lua';
    'lua/tserialize.lua';
    'lua/tstr.lua';
  }

  local table_exports_keys = tset(tkeys(table_exports))

  for _, table_related_file in ipairs(table_related_files) do
    local exports = import(table_related_file) ()
    for name, value in pairs(exports) do
      ensure_equals("we have this key", table_exports[name], value)
      table_exports_keys[name] = nil
    end
  end

  ensure_equals("no extra keys are exported", next(table_exports_keys), nil)
end)

--------------------------------------------------------------------------------

assert(test:run())
