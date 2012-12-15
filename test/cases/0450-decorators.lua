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
      ensure_fails_with_substring,
      ensure_is,
      ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_tequals',
        'ensure_fails_with_substring',
        'ensure_is',
        'ensure',
        'ensure_equals'
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
      environment_values,
      decorators_exports
      = import 'lua-nucleo/testing/decorators.lua'
      {
        'decoraror_checker_helper',
        'check_decorator',
        'environment_values'
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

  check_decorator(environment_values(values), tkeys(values))
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
        check_decorator(environment_values({ }), { }, nil, true)
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
        check_decorator(environment_values(values), { "key", "missing" })
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
        check_decorator(environment_values(values), { "key" })
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
            environment_values(values),
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

--------------------------------------------------------------------------------

-- NOTE: environment_values is tested without check_decorator, because
--       tests for check_decorator uses environment_values
test:group "environment_values"

test:case "add-and-remove-values" (function(test_env)
  local values =
  {
    key = "value";
    numeric = 42;
  }
  local called_ok = false
  local good_fake_test = function(test_env)
    ensure_equals("new env values was added: key", test_env.key, "value")
    ensure_equals("new env values was added: numeric", test_env.numeric, 42)
    called_ok = true
  end

  local decorator = environment_values(values)
  ensure_is("decorator is function", decorator, "function")

  local wrapped = decorator(good_fake_test)
  ensure_is("decorated test is function", decorator, "function")

  wrapped(test_env)
  ensure("good_fake_test was called", called_ok)
  ensure_equals("new env values was removed: key", test_env.key, nil)
  ensure_equals("new env values was removed: numeric", test_env.numeric, nil)
end)

local original_values =
{
  original_key = "original value";
  original_numeric = 42;
}

test:case "keep-original-values"
  :with(environment_values(original_values)) (function(test_env)
  local values =
  {
    key = "value";
    numeric = 4242;
  }
  local called_ok = false
  local good_fake_test = function(test_env)
    called_ok = true
  end

  local decorator = environment_values(values)
  ensure_is("decorator is function", decorator, "function")

  local wrapped = decorator(good_fake_test)
  ensure_is("decorated test is function", decorator, "function")

  ensure_tequals("original values is set", test_env, original_values)
  wrapped(test_env)
  ensure("good_fake_test was called", called_ok)
  ensure_tequals("original values is kept", test_env, original_values)
end)

--------------------------------------------------------------------------------
