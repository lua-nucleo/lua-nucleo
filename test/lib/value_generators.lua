-- value-generators.lua: Lua value generators for tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local newproxy = newproxy
local math_random, math_pi = math.random, math.pi
local coroutine_create = coroutine.create

local invariant,
      remove_nil_arguments
      = import 'lua-nucleo/functional.lua'
      {
        'invariant',
        'remove_nil_arguments'
      }

local empty_table
      = import 'lua-nucleo/table.lua'
      {
        'empty_table'
      }

-- TODO: Let user to select features, like nil, NaN etc.
-- TODO: Random_string().
local make_value_generators = function(features)
  features = features or empty_table
  return
  {
    -- WARNING: Beware of maximum number of arguments limit!
    remove_nil_arguments(
      features["nil"]
        and invariant(nil),
      invariant(true),
      invariant(false),
      (not features["no-numbers"]) and invariant(-42) or nil,
      (not features["no-numbers"]) and invariant(-1) or nil,
      (not features["no-numbers"]) and invariant(0) or nil,
      (not features["no-numbers"])
        and function()
          return math_random()
        end
        or nil,
      (not features["no-numbers"])
        and function()
          return math_random(-1e8, 1e8)
        end
        or nil,
      (not features["no-numbers"]) and invariant(1) or nil,
      (not features["no-numbers"]) and invariant(42) or nil,
      (not features["no-numbers"]) and invariant(math_pi) or nil,
      (not features["no-numbers"]) and features["nan"]
        and invariant(0/0)
        or nil,
      (not features["no-numbers"]) and invariant(1/0) or nil,
      (not features["no-numbers"]) and invariant(-1/0) or nil,
      invariant(""),
      invariant("The Answer to the Ultimate Question of Life, the Universe, and Everything"),
      invariant("embedded\0zero"),
      invariant("multiline\nstring"),
      -- TODO: Random_string().
      invariant({ }),
      invariant({ 1 }),
      invariant({ a = 1 }),
      invariant({ a = 1, 1 }),
      invariant({ [{}] = {} }),
      features["recursive-table"]
        and function()
          local t = { }
          t[t] = t
          return t
        end,
      invariant(function() end),
      features["function-with-upvalues"]
        and function()
          local upvalue = true
          return function()
            return upvalue
          end
        end,
      invariant(coroutine_create(function() end)),
      features["userdata"]
        and invariant(newproxy())
    )
  }
end

return
{
  make_value_generators = make_value_generators;
}
