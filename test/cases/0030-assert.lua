--------------------------------------------------------------------------------
-- 0030-assert.lua: tests for enhanced assertions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local lassert,
      assert_exports
      = import 'lua-nucleo/assert.lua'
      {
        'lassert'
      }

--------------------------------------------------------------------------------

local test = make_suite("assert", assert_exports)

--------------------------------------------------------------------------------

test:test_for "lassert" (function()
  ensure_tequals("success", { lassert(42, true, "msg", 1) }, { true, "msg", 1 })

  ensure_fails_with_substring(
      "failure",
      function()
        local outer_function = function()
          local inner_function = function()
            lassert(2, nil, "my_error_message", 1)
          end

          inner_function() -- Should point here
        end

        outer_function()
      end,
      "assert.lua:43: my_error_message" -- TODO: HACK. Keep line number up-to-date
    )
end)

--------------------------------------------------------------------------------

assert(test:run())
