--------------------------------------------------------------------------------
-- 0450-decorators.lua: Test for check_decorator and friends
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_tequals'
      }

local tclone,
      tkeys,
      toverride_many
      = import 'lua-nucleo/table-utils.lua'
      {
        'tclone',
        'tkeys',
        'toverride_many'
      }

local evaluate_decorator,
      check_decorator,
      decorators_exports
      = import 'lua-nucleo/testing/decorators.lua'
      {
        'evaluate_decorator',
        'check_decorator'
      }

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)
local test = make_suite("decorators", decorators_exports)

--------------------------------------------------------------------------------

test:tests_for 'evaluate_decorator'

test:case 'evaluate_decorator_ok' (function()
  local called = { }
  local make_decorator = function(key)
    return function(test_fn)
      return function(env)
        local pass = env.pass or 0
        env.pass = pass + 1
        called[key] = env.pass
        test_fn(env)
      end
    end
  end

  local before = make_decorator("before")
  local decorator = make_decorator("decorator")
  local after = make_decorator("after")
  local test = function(env)
    called["test"] = env.pass + 1
  end

  evaluate_decorator(decorator, before, after, test)

  ensure_tequals(
      "functions called in correct order",
      called,
      {
        decorator = 2;
        before = 1;
        after = 3;
        test = 4;
      }
    )
end)

test:group "check_decorator"

--- Making "good" decorator, who adding own values, and remove them when finish
local good_decorator_factory = function(values)
  values = values or { }
  return function(test_fn)
    return function(env)
      local new_env = tclone(env)
      toverride_many(new_env, values)
      test_fn(new_env)
    end
  end
end

--- Make decorator which "forgot" garbage in environment
local garbage_decorator_factory = function(garbage)
  garbage = garbage or { }
  return function(test_fn)
    return function(env)
      test_fn(env)
      toverrude_many(env, garbage)
    end
  end
end

test:case 'check_decorator_ok' (function()
  local values =
    {
      key = "value";
      numeric = 42;
    }
  check_decorator(good_decorator_factory(values), tkeys(values))
end)
