--------------------------------------------------------------------------------
-- 0010-algorithm.lua: tests for various common algorithms
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local assert_is_table,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_number'
      }

local ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
      }

local validate_probability_rough,
      validate_probability_precise
      = import 'lua-nucleo/random.lua'
      {
        'validate_probability_rough',
        'validate_probability_precise'
      }

local invariant
      = import 'lua-nucleo/functional.lua'
      {
        'invariant'
      }

local tdeepequals,
      tstr,
      taccumulate,
      tnormalize,
      tgenerate_n,
      tclone
      = import 'lua-nucleo/table.lua'
      {
        'tdeepequals',
        'tstr',
        'taccumulate',
        'tnormalize',
        'tgenerate_n',
        'tclone'
      }

local lower_bound,
      lower_bound_pred,
      lower_bound_gt,
      upper_bound,
      upper_bound_pred,
      upper_bound_gt,
      pick_init,
      pick_one,
      algorithm_exports
      = import 'lua-nucleo/algorithm.lua'
      {
        'lower_bound',
        'lower_bound_pred',
        'lower_bound_gt',
        'upper_bound',
        'upper_bound_pred',
        'upper_bound_gt',
        'pick_init',
        'pick_one'
      }

--------------------------------------------------------------------------------

local test = make_suite("algorithm", algorithm_exports)

--------------------------------------------------------------------------------

-- TODO: Test lower and upper bound better!

local check_bound = function(name, bound_fn, pred, t, k, expected_value)
  local actual_value
  if pred then
    actual_value = bound_fn(t, 1, k, pred)
  else
    actual_value = bound_fn(t, 1, k)
  end
  if actual_value ~= expected_value then
    error(
        ("check %s: bad actual value %q, expected %q\n"):format(
            name, tostring(actual_value), tostring(expected_value)
          ),
        2
      )
  end
end

--------------------------------------------------------------------------------

test:test_for "lower_bound" (function()
  local check = function(...)
    return check_bound("lower_bound", lower_bound, nil, ...)
  end

  check({ {1}, {2} }, 1.5, 2)
  check({ {1}, {2} }, 0, 1)
  check({ {1}, {2} }, 1, 1)
  check({ {1}, {2} }, 2, 2)
  check({ {1}, {2} }, 3, 3)

  check({ {1}, {2}, {2}, {3} },   2, 2)
  check({ {1}, {2}, {2}, {3} }, 2.5, 4)
  check({ {1}, {2}, {2}, {3} }, 1.5, 2)
end)

test:test_for "lower_bound_gt" (function()
  local check = function(...)
    return check_bound("lower_bound_gt", lower_bound_gt, nil, ...)
  end

  check({ {2}, {1} }, 1.5, 2)
  check({ {2}, {1} }, 0, 3)
  check({ {2}, {1} }, 1, 2)
  check({ {2}, {1} }, 2, 1)
  check({ {2}, {1} }, 3, 1)

  check({ {3}, {2}, {2}, {1} },   2, 2)
  check({ {3}, {2}, {2}, {1} }, 2.5, 2)
  check({ {3}, {2}, {2}, {1} }, 1.5, 4)
end)

--------------------------------------------------------------------------------

test:group "lower_bound_pred"

--------------------------------------------------------------------------------

test "lower_bound_pred-lt" (function()
  local check = function(...)
    return check_bound(
        "lower_bound_pred",
        lower_bound_pred,
        function(lhs, rhs) return lhs[1] < rhs[1] end,
        ...
      )
  end

  check({ {{1}}, {{2}} }, {1.5}, 2)
  check({ {{1}}, {{2}} }, {0}, 1)
  check({ {{1}}, {{2}} }, {1}, 1)
  check({ {{1}}, {{2}} }, {2}, 2)
  check({ {{1}}, {{2}} }, {3}, 3)

  check({ {{1}}, {{2}}, {{2}}, {{3}} },   {2}, 2)
  check({ {{1}}, {{2}}, {{2}}, {{3}} }, {2.5}, 4)
  check({ {{1}}, {{2}}, {{2}}, {{3}} }, {1.5}, 2)
end)

test "lower_bound_pred-gt" (function()
  local check = function(...)
    return check_bound(
        "lower_bound_pred",
        lower_bound_pred,
        function(lhs, rhs) return lhs[1] > rhs[1] end,
        ...
      )
  end

  check({ {{2}}, {{1}} }, {1.5}, 2)
  check({ {{2}}, {{1}} }, {0}, 3)
  check({ {{2}}, {{1}} }, {1}, 2)
  check({ {{2}}, {{1}} }, {2}, 1)
  check({ {{2}}, {{1}} }, {3}, 1)

  check({ {{3}}, {{2}}, {{2}}, {{1}} },   {2}, 2)
  check({ {{3}}, {{2}}, {{2}}, {{1}} }, {2.5}, 2)
  check({ {{3}}, {{2}}, {{2}}, {{1}} }, {1.5}, 4)
end)

--------------------------------------------------------------------------------

test:test_for "upper_bound" (function()
  local check = function(...)
    return check_bound("upper_bound", upper_bound, nil, ...)
  end

  check({ {1}, {2} }, 1.5, 2)
  check({ {1}, {2} }, 0, 1)
  check({ {1}, {2} }, 1, 2)
  check({ {1}, {2} }, 2, 3)
  check({ {1}, {2} }, 3, 3)

  check({ {1}, {2}, {2}, {3} },   2, 4)
  check({ {1}, {2}, {2}, {3} }, 2.5, 4)
  check({ {1}, {2}, {2}, {3} }, 1.5, 2)
end)

test:test_for "upper_bound_gt" (function()
  local check = function(...)
    return check_bound("upper_bound_gt", upper_bound_gt, nil, ...)
  end

  check({ {2}, {1} }, 1.5, 2)
  check({ {2}, {1} }, 0, 3)
  check({ {2}, {1} }, 1, 3)
  check({ {2}, {1} }, 2, 2)
  check({ {2}, {1} }, 3, 1)

  check({ {3}, {2}, {2}, {1} },   2, 4)
  check({ {3}, {2}, {2}, {1} }, 2.5, 2)
  check({ {3}, {2}, {2}, {1} }, 1.5, 4)
end)

--------------------------------------------------------------------------------

test:group "upper_bound_pred"

--------------------------------------------------------------------------------

test "upper_bound_pred-lt" (function()
  local check = function(...)
    return check_bound(
        "upper_bound_pred",
        upper_bound_pred,
        function(lhs, rhs) return lhs[1] < rhs[1] end,
        ...
      )
  end

  check({ {{1}}, {{2}} }, {1.5}, 2)
  check({ {{1}}, {{2}} }, {0}, 1)
  check({ {{1}}, {{2}} }, {1}, 2)
  check({ {{1}}, {{2}} }, {2}, 3)
  check({ {{1}}, {{2}} }, {3}, 3)

  check({ {{1}}, {{2}}, {{2}}, {{3}} },   {2}, 4)
  check({ {{1}}, {{2}}, {{2}}, {{3}} }, {2.5}, 4)
  check({ {{1}}, {{2}}, {{2}}, {{3}} }, {1.5}, 2)
end)

test "upper_bound_pred-gt" (function()
  local check = function(...)
    return check_bound(
        "upper_bound_pred",
        upper_bound_pred,
        function(lhs, rhs) return lhs[1] > rhs[1] end,
        ...
      )
  end

  check({ {{2}}, {{1}} }, {1.5}, 2)
  check({ {{2}}, {{1}} }, {0}, 3)
  check({ {{2}}, {{1}} }, {1}, 3)
  check({ {{2}}, {{1}} }, {2}, 2)
  check({ {{2}}, {{1}} }, {3}, 1)

  check({ {{3}}, {{2}}, {{2}}, {{1}} },   {2}, 4)
  check({ {{3}}, {{2}}, {{2}}, {{1}} }, {2.5}, 2)
  check({ {{3}}, {{2}}, {{2}}, {{1}} }, {1.5}, 4)
end)

--------------------------------------------------------------------------------

test:tests_for "pick_init"
               "pick_one"

--------------------------------------------------------------------------------

test "pick-empty" (function()
  local probs = {}
  local data = assert_is_table(pick_init(probs))
  local result = pick_one(data)
  ensure_equals("no data picked", result, nil)
end)

test "pick-single-one" (function()
  local probs = { single = 1 }
  local data = assert_is_table(pick_init(probs))
  local result = pick_one(data)
  ensure_equals("single picked", result, "single")
end)

test "pick-single-zero-ignored" (function()
  local probs = { zero = 0 }
  local data = assert_is_table(pick_init(probs))
  local result = pick_one(data)
  ensure_equals("single zero not picked", result, nil)
end)

test "pick-zero-ignored-nonzero-picked" (function()
  local probs = { zero = 0, nonzero = 1 }
  local data = assert_is_table(pick_init(probs))
  local result = pick_one(data)
  ensure_equals("no data picked", result, "nonzero")
end)

local generate = function(num_experiments, length, probabilities)
  local data = assert_is_table(pick_init(probabilities))
  local experiments = {}
  if length > 0 then
    experiments = tgenerate_n(length, invariant(0))
  else
    for k, _ in pairs(probabilities) do
      experiments[k] = 0
    end
  end
  for i = 1, num_experiments do
    local result = pick_one(data)
    assert(experiments[result])
    experiments[result] = experiments[result] + 1
  end
  return experiments
end

test "pick-equal-weights" (function()
  local num_runs = 1e5
  local probs = { alpha = 1, beta = 1 }

  print("generating stats...")
  local stats = generate(num_runs, 0, probs)
  print("done generating stats")

  assert(validate_probability_rough(probs, stats))
  if test:in_strict_mode() then
    local res, err = validate_probability_precise(probs, generate, 0, probs)
    if not res then
       error(err or "Test failed!")
    end
  end
end)

test "pick-non-equal-weights" (function()
  local num_runs = 1e5

  local probs = { alpha = 0.5, beta = 2 }

  print("generating stats...")
  local stats = generate(num_runs, 0, probs)
  print("done generating stats")

  assert(validate_probability_rough(probs, stats))
  if test:in_strict_mode() then
    local res, err = validate_probability_precise(probs, generate, 0, probs)
    if not res then
      error(err or "Test failed!")
    end
  end
end)

test "pick-non-equal-weights-generated" (function()
  local num_keys = 1e2
  local num_runs = 1e5

  local probs = tgenerate_n(
      num_keys,
      function()
        -- We want large non-integer numbers
        -- TODO: Looks funny
        return math.random(10, 100) + math.random()
      end
    )

  print("generating stats...")
  local stats = generate(num_runs, num_keys, probs)
  print("done generating stats")

  assert(validate_probability_rough(probs, stats))
  if test:in_strict_mode() then
    local res, err = validate_probability_precise(
        probs,
        generate,
        num_keys,
        probs
      )
    if not res then
      error(err or "Test failed!")
    end
  end
end)
