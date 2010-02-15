-- math.lua: math-related utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

math.randomseed(12345)

--------------------------------------------------------------------------------

local assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number'
      }

local ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
      }

--------------------------------------------------------------------------------

local EPSILON,
      trunc,
      math_exports
      = import 'lua-nucleo/math.lua'
      {
        'EPSILON',
        'trunc'
      }

--------------------------------------------------------------------------------

local test = make_suite("math", math_exports)

--------------------------------------------------------------------------------

test:test_for "EPSILON" (function()
  assert_is_number(EPSILON)

  local num_iter = 0

  -- http://en.wikipedia.org/wiki/Machine_epsilon
  local actual_epsilon = 1
  while 1 + actual_epsilon ~= 1 do
    actual_epsilon = actual_epsilon / 2

    num_iter = num_iter + 1
    assert(
        num_iter < 1e6,
        "no epsilon for this architecture?!"
      )
  end

  -- May fail if Lua is not compiled with number as double.
  -- Change EPSILON accordingly then.
  ensure_equals("EPSILON", EPSILON, actual_epsilon)
end)

--------------------------------------------------------------------------------

test:tests_for "trunc"

test "trunc-basic" (function()
  ensure_equals("fractional, >0", trunc(3.14), 3)
  ensure_equals("fractional, <0", trunc(-3.14), -3)

  ensure_equals("integral, >0", trunc(42), 42)
  ensure_equals("integral, <0", trunc(-42), -42)

  ensure_equals("zero", trunc(0.00), 0)

  ensure_equals("+inf", trunc(math.huge), math.huge)
  ensure_equals("-inf", trunc(-math.huge), -math.huge)

  do
    local truncated_nan = trunc(0/0)
    ensure("nan", truncated_nan ~= truncated_nan)
  end
end)

test "trunc-random" (function()
  local num_iter = 1e6
  for i = 1, num_iter do
    local sign = (math.random() >= 0.5) and 1 or -1
    local int = math.random(2 ^ 29)
    local frac = math.random()

    local num = sign * (int + frac)

    ensure_equals("random check", trunc(num), sign * int)
  end
end)

--------------------------------------------------------------------------------

assert(test:run())
