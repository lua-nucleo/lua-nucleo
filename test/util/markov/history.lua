-- history.lua: tests for Markov chain history
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Must have similar auto-validation function for object methods
--       as we have for file exports. Object method as in table field
--       with function typed value, without "_" at the end.
--       Note that it should be orthogonal to the exports stuff.

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
      }

local history_imports = import 'lua-nucleo/util/markov/history.lua' ()

--------------------------------------------------------------------------------

local test = make_suite("history", history_imports)

--------------------------------------------------------------------------------

test:group "make_history"

--------------------------------------------------------------------------------

test "make_history" (function()
  error("TODO: Implement!")
end)

test "history-push" (function()
  error("TODO: Implement!")
end)

test "history-tostring" (function()
  error("TODO: Implement!")
end)

test "history-toprefixform" (function()
  error("TODO: Implement!")
end)

test "history-get" (function()
  error("TODO: Implement!")
end)

test "history-ipairs" (function()
  error("TODO: Implement!")
end)

--------------------------------------------------------------------------------

assert(test:run())
