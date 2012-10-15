--------------------------------------------------------------------------------
-- decorators-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite("decorators-suite", { })

test:set_up (function(test_env) test_env["status"] = "set up" end)
test:tear_down (function(test_env)
  assert(test_env.status == "tear down", "test passed")
end)

local decorator = function(decorated_test)
  return function(test_env)
    assert(test_env.status == "set up", "setup passed")
    test_env.status = "decorated"
    return decorated_test(test_env)
  end
end

test "decorated" :with(decorator) (function(env)
  assert(env.status == "decorated", "test decorated")

  -- Later check this value in tear down hook
  env.status = "tear down"
end)
