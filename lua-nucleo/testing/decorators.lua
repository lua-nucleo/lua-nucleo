--------------------------------------------------------------------------------
--- Decorators validation helper
-- @module lua-nucleo.testing.decorator
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local do_nothing
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing'
      }

local ensure,
      ensure_returns,
      ensure_equals,
      ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_returns',
        'ensure_equals',
        'ensure_tequals'
      }

local tclone,
      tkeys,
      tijoin_many,
      toverride_many
      = import 'lua-nucleo/table-utils.lua'
      {
        'tclone',
        'tkeys',
        'tijoin_many',
        'toverride_many'
      }

local run_test
      = import 'lua-nucleo/suite.lua'
      {
        'run_test'
      }

local table_sort = table.sort

--------------------------------------------------------------------------------

local evaluate_decorator = function(
    decorator_fn,
    before_fn,
    after_fn,
    test_fn
  )
  return ensure_returns(
      "decorator is evaluated as correct",
      3, { true, nil, nil },
      run_test(
          function(...)
            local fake_suite = (...)("fake_suite")
            fake_suite:test "fake"
              :with(before_fn)
              :with(decorator_fn)
              :with(after_fn)(test_fn)
          end,
          {
            seed_value = 12345;
            strict_mode = true;
          }
        )
    )
end

local ensure_no_keys = function(msg, env, keys)
  for i = 1, #keys do
    ensure(msg .. ": key: " .. tostring(keys[i]) , not env[keys[i]])
  end
end

local make_before_decorator_checker = function(keys, exists_values)
  local before_decorator = function(test_fn)
    return function(env)
      ensure_no_keys("keys not exists before decorator", env, keys)
      toverride_many(env, exists_values)
      local copy = tclone(env)
      test_fn(env)
      ensure_no_keys("keys not exists after decorator", env, keys)
      ensure_tequals(
          "no garbage after decorated function",
          env,
          copy
        )
    end
  end
  return before_decorator
end

local make_after_decorator_checker = function(keys, exists_values)
  local called = false
  local checker_decorator = function(test_fn)
    return function(env)
      for key, val in pairs(exists_values) do
        ensure_equals("passed values not modified", env[key], val)
      end
      for i = 1, #keys do
        ensure("required values set in environment", env[keys[i]])
      end
      local existing_keys = tijoin_many(tkeys(exists_values), keys)
      local env_keys = tkeys(env)
      table_sort(existing_keys)
      table_sort(env_keys)
      ensure_tequals(
          "no unwanted keys in environment",
          existing_keys,
          env_keys
        )
      called = true
    end
  end
  local is_called = function()
    return called
  end
  return checker_decorator, is_called
end

local check_decorator = function(
    decorator,
    keys,
    good_test,
    expected_skip,
    stuff
  )
  good_test = good_test or do_nothing
  stuff = stuff or { }

  local before_fn = make_before_decorator_checker(keys)
  local after_fn, is_called = make_after_decorator_checker(keys, stuff)
  evaluate_decorator(decorator, before_fn, after_fn, good_test)

  local called = is_called()
  if expected_skip then
    ensure_equals("decorated test skipped", called, false)
  else
    ensure_equals("decorated test called", called, true)
  end
  return true
end

return
{
  check_decorator = check_decorator;

  -- Not part of API, but exported for unit testing and also may be useful
  -- for other high-level tests.
  evaluate_decorator = evaluate_decorator;
}
