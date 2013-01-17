--------------------------------------------------------------------------------
-- complex-factory-decorated-function.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)

-- state set in factory decorator, and later checked in regular test
local state = false

local decorator = function(fn)
  return function(env)
    env.test_value_set = true
    state = true
    return fn(env)
  end
end

local make_some = function(env)
  assert(env.test_value_set, "test value not set")
  local method1 = function() end
  return
  {
    method1 = method1
  }
end

local test = make_suite(
    "complex-factory-decorated-function-input",
    {
      make_some = true,
    }
  )

test:factory "make_some" :with(decorator) (make_some)
test:method "method1" (function(env)
  assert(state, "state not set")
end)
