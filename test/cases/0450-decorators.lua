--------------------------------------------------------------------------------
-- 0450-decorators.lua: Test for check_decorator and friends
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local do_nothing
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing'
      }

local ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_tequals',
        'ensure_fails_with_substring'
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

local decoraror_checker_helper,
      check_decorator,
      decorators_exports
      = import 'lua-nucleo/testing/decorators.lua'
      {
        'decoraror_checker_helper',
        'check_decorator'
      }

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)
local test = make_suite("decorators", decorators_exports)

--------------------------------------------------------------------------------

test:tests_for 'decoraror_checker_helper'

test:case 'evaluate_decorator_ok' (function()
  local called = { }
  local create_decorator = function(key)
    return function(test_fn)
      return function(env)
        local pass = env.pass or 0
        env.pass = pass + 1
        called[key] = env.pass
        test_fn(env)
      end
    end
  end

  local before = create_decorator("before")
  local decorator = create_decorator("decorator")
  local after = create_decorator("after")
  local test = function(env)
    called["test"] = env.pass + 1
  end

  decoraror_checker_helper(decorator, before, after, test)

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
local create_good_decorator = function(values)
  values = values or { }
  return function(test_fn)
    return function(env)
      local new_env = tclone(env)
      toverride_many(new_env, values)
      test_fn(new_env)
    end
  end
end

--- Make decorator which "forgets" garbage in environment
local create_littering_decorator = function(garbage)
  garbage = garbage or { }
  return function(test_fn)
    return function(env)
      test_fn(env)
      toverride_many(env, garbage)
    end
  end
end

local skip_decorator = function(test_fn)
  return do_nothing
end

test:case 'check_decorator_ok' (function()
  local values =
  {
    key = "value";
    numeric = 42;
  }

  check_decorator(create_good_decorator(values), tkeys(values))
end)

test:case "check_decorator_do_nothing" (function()
  check_decorator(skip_decorator, { }, nil, true)
  ensure_fails_with_substring(
      "decorated function not called, as requested",
      function()
        check_decorator(skip_decorator, { }, nil, false)
      end,
      "decorated test not skipped"
    )
  ensure_fails_with_substring(
      "decorated function should not called, but does",
      function()
        check_decorator(create_good_decorator({ }), { }, nil, true)
      end,
      "decorated test skipped"
    )
end)

test:case "check_decorator_and_missing_keys" (function()
  local values =
  {
    key = "value";
  }

  ensure_fails_with_substring(
      "missing keys are catching",
      function()
        check_decorator(create_good_decorator(values), { "key", "missing" })
      end,
      "broken decorator: required values not set in environment"
    )
end)

test:case "check_decorator_and_unwanted_keys" (function()
  local values =
  {
    key = "value";
    numeric = 42;
  }

  ensure_fails_with_substring(
      "unwanted keys are catched",
      function()
        check_decorator(create_good_decorator(values), { "key" })
      end,
      "broken decorator: unwanted keys in environment"
    )
end)

test:case "check_decorator_and_mangled_environment" (function()
  local values =
  {
    key = "value";
    numeric = 42;
  }
  local other_values =
  {
    key = "other value";
    numeric = 142;
  }

  ensure_fails_with_substring(
      "detection of mangled environment",
      function()
        check_decorator(
            create_good_decorator(values),
            { },
            nil,
            false,
            other_values
          )
      end,
      "broken decorator: passed values mangled"
    )
end)

test:case "check_decorator_and_garbage" (function()
  local values =
  {
    key = "value";
    numeric = 42;
  }

  ensure_fails_with_substring(
      "garbage after decorator",
      function()
        check_decorator(create_littering_decorator(values), { })
      end,
      "broken decorator: garbage after decorated function"
    )
end)
