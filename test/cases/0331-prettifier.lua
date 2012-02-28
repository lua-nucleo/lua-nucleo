--------------------------------------------------------------------------------
-- 0331-tpretty.lua: tests for pretty-printer prettifier
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local make_prettifier,
      prettifier_exports
      = import 'lua-nucleo/prettifier.lua'
      {
        'make_prettifier'
      }

local table_concat = table.concat

--------------------------------------------------------------------------------

local test = make_suite("prettifier", prettifier_exports)

--------------------------------------------------------------------------------

test:factory("make_prettifier", make_prettifier)

--------------------------------------------------------------------------------

test:TODO "test make_prettifier"

--------------------------------------------------------------------------------
-- Test based on real bug scenario
-- #2304 and #2317
test "test broken behaivor" (function ()
  local buf = {}
  local indent = "  "
  local cols = 80

  -- initialize (as in tpretty())
  local cat = function(v) buf[#buf + 1] = v end
  local pr = make_prettifier(indent, buf, cols)

  -- emulate failing serialization
  pr:table_start()
  pr:key_start()
  cat("key")
  pr:value_start()
  cat("value")
  pr:key_value_finish()
  pr:table_finish()
  pr:finished()

  -- then check
  ensure_strequals("not broken", table_concat(buf), "{ key = value }");
end)

--------------------------------------------------------------------------------

assert(test:run())
