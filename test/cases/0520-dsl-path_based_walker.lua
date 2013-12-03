--------------------------------------------------------------------------------
-- 0520-dsl-path_based_walker: Tests for path-based data walker
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ensure,
      ensure_equals,
      ensure_tdeepequals,
      ensure_returns
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tdeepequals',
        'ensure_returns'
      }

local tclone
      = import 'lua-nucleo/table-utils.lua'
      {
        'tclone'
      }

--------------------------------------------------------------------------------

local make_path_based_walker,
      imports
      = import 'lua-nucleo/dsl/path_based_walker.lua'
      {
        'make_path_based_walker'
      }

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)
local test = make_suite("path_based_walker", imports)

--------------------------------------------------------------------------------

test:tests_for 'make_path_based_walker'

--------------------------------------------------------------------------------

test "smoke" (function()
  local log = { }

  local logger = function(expected_self, dir)
    return setmetatable(
        { },
        {
          __index = function(t, k)
            k = tclone(k) -- Note: k is mutable and will be changed
            return function(self, node)
              ensure_equals("correct self", self, expected_self)
              log[#log + 1] = { dir, k, node }
              return #log
            end
          end;
        }
      )
  end

  local rules = { }
  rules.up = logger(rules, "up")
  rules.down = logger(rules, "down")

  local walker = ensure("create walker", make_path_based_walker(rules))

  local calls =
  {
    { "down", "alpha", { "alpha-v" } };
    { "down", "beta", { "beta-v" } };
    { "up", "beta", { "beta-v" } };
    { "up", "alpha", { "alpha-v" } };
  }

  for i = 1, #calls do
    ensure_returns(
        "call " .. i,
        1, { #log + 1 },
        walker[calls[i][1]][calls[i][2]](walker, calls[i][3])
      )
  end

  ensure_tdeepequals(
      "log check",
      log,
      {
        { "down", { "alpha" }, { "alpha-v" } };
        { "down", { "alpha", "beta" }, { "beta-v" } };
        { "up", { "alpha", "beta" }, { "beta-v" } };
        { "up", { "alpha" }, { "alpha-v" } };
      }
    )
end)

--------------------------------------------------------------------------------
