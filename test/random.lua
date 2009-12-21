-- random.lua: tests for utilities for random generation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

math.randomseed(12345)

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_fails_with_substring',
      }

local tgenerate_n
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgenerate_n',
      }

local taccumulate,
      tnormalize,
      tclone
      = import 'lua-nucleo/table.lua'
      {
        'taccumulate',
        'tnormalize',
        'tclone'
      }

local validate_probability_rough,
      validate_probability_precise,
      random_exports
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

--------------------------------------------------------------------------------

local test = make_suite("random", random_exports)

--------------------------------------------------------------------------------

local pairs, print, error = pairs, print, error
local math_random = math.random

-- test global constants, define number of elements (cases) in tested tables
local START_POINT = 2 -- can't be less then 2, or more then END_POINT
local MIDDLE_POINT = 10
local END_POINT = 100 -- cant be more then 100, or less then START_POINT
local STEP_SMALL = 2 -- before MIDDLE_POINT
local STEP_LARGE = 30 -- after MIDDLE_POINT
-- if we need full test use further values:
-- START_POINT = 2
-- MIDDLE_POINT = 10
-- END_POINT = 100
-- STEP_SMALL = 1
-- STEP_LARGE = 1

-- step of tests
local get_next_iteration = function(i)
  if i < MIDDLE_POINT then
    i = i + STEP_SMALL
  else
    i = i + STEP_LARGE
  end
  return i
end

local table_sort = table.sort

-- generates distribution table, where keys are cases and
-- values - number of experiments fallen in this case
local generate_experiments = function(
    num_experiments, -- number of experiments to generate
    weights -- table, contains weights of each case
  )
  local weights_normalized = tnormalize(weights)
  local experiments = {}
  -- table, that contains formalized information on each case
  local formalized = {}
  local probability = 0

  -- filling formalized table
  for k, v in pairs(weights) do
    experiments[k] = 0
    local cached = probability + weights_normalized[k]
    formalized[#formalized + 1] =
    {

      cached - probability;
      name = k;
      lowBound = probability;
      upBound = cached;
    }
    probability = cached
  end

  -- sorting formalized by chance of hitting case
  table_sort(formalized, function(a, b) return a[1] > b[1] end)

  -- carrying out experiments
  for i = 1, num_experiments do
    local experiment = math_random()
    for i = 1, #formalized do
      if
        experiment >= formalized[i].lowBound
        and experiment < formalized[i].upBound
      then
        local name = formalized[i].name
        experiments[name] = experiments[name] + 1
        break
      end
    end
  end

  return experiments
end

-- generates indexed table with length n, and random numbers in values
local generate_weights = function(n)
  return tgenerate_n(n, math_random)
end

local os_clock = os.clock

--------------------------------------------------------------------------------

test:group "validate_probability_rough"

--------------------------------------------------------------------------------

test 'validate_probability_rough-input' (function()
  print("Wrong inputs:")
  ensure_fails_with_substring(
      "wrong arguments",
      function() validate_probability_rough("a") end,
      "expected `table', got `string'"
    )
  ensure_fails_with_substring(
      "wrong arguments",
      function() validate_probability_rough({1}, "b") end,
      "expected `table', got `string'"
    )
  local res, err = validate_probability_rough({1, 3}, {3, 5, 6})
  if err ~= nil then print(err) else error("wrong input") end
  res, err = validate_probability_rough({1}, {1})
  if err ~= nil then print(err) else error("wrong input") end
  res, err = validate_probability_rough({1, 2, 3}, {1, 2, 3})
  if err ~= nil then print(err) else error("wrong input") end
end)

--------------------------------------------------------------------------------

test 'validate_probability_rough-simple1' (function()
  local weights = {0,5; 0,5}
  if validate_probability_rough(weights, generate_experiments(1000, weights)) then
    error("Simple test failed.")
  end
end)

test 'validate_probability_rough-simple2' (function()
  local weights = {0,5; 0,25; 0,25}
  if validate_probability_rough(weights, generate_experiments(1000, weights)) then
    error("Simple test failed.")
  end
end)

test 'validate_probability_rough-simple3' (function()
  local weights = {0,6; 0,3; 0,05; 0,05}
  if validate_probability_rough(weights, generate_experiments(1000, weights)) then
    error("Simple test failed.")
  end
end)

test 'validate_probability_rough-simple4' (function()
  -- simple wrong test
  if validate_probability_rough({0.6, 0.4}, generate_experiments(1000, {0.4, 0.6})) ~= false then
    error("Simple test failed.")
  end
end)

--------------------------------------------------------------------------------

test 'validate_probability_rough-complex' (function()
  -- generates data, tests function validate_probability_rough on this data
  -- and returns number of true checks
  local check = function(
      num_cycles, -- number of cycles of testing
      length, -- number of cases (keys) in weights and experiments
      weights, -- table, contains weights of each case
      experiments, -- table, contains experiments
      should_generate_weights, -- if we generate other weights for each test
      should_generate_experiments, -- if we generate other experiments for test
      num_experiments, -- generated, if previous true
      weights_to_use -- used to generate experiments if needed
    )

    -- default values
    should_generate_weights = should_generate_weights or false
    should_generate_experiments = should_generate_experiments or false
    num_experiments = num_experiments or 10^4
    if weights_to_use == nil then weights_to_use = weights end

    -- testing cycle
    local true_checks = 0
    local weights_current = weights
    local experiments_current = experiments
    for i = 1, num_cycles do
      if should_generate_weights then
        weights_current = generate_weights(length)
      end
      if should_generate_experiments then
        experiments_current = generate_experiments(
            num_experiments,
            weights_to_use
          )
      end
      if validate_probability_rough(weights_current, experiments_current) then
        true_checks = true_checks + 1
      end
    end

    return true_checks
  end

  -- test step constants
  local NUM_SET = 1000
  local NUM_CYCLES = 100

  local start = os_clock()

  -- all testing inside
  print("Random test")
  print("Experiments number in set: " .. NUM_SET)
  local table_size = START_POINT
  while table_size <= END_POINT do

    -- false positive check
    local num_experiments = check(
        NUM_CYCLES,
        table_size,
        {},
        generate_experiments(NUM_SET, generate_weights(table_size)),
        true
      )
    print("Table size: " .. table_size .. " keys, false data")
    print(num_experiments .. " of " .. NUM_CYCLES .. " false positive.")

    -- function broken, function cant randomly fail 100 of 100 times
    -- can be 10 of 100 or even 40 of 100
    if num_experiments == 100 then
      error("Test failed!")
    end
    print("OK")

    -- false negative check
    num_experiments = NUM_CYCLES - check(
        NUM_CYCLES,
        table_size,
        generate_weights(table_size),
        {},
        false,
        true,
        NUM_SET
      )
    print("Table size: " .. table_size .. " keys, correct data")
    print(num_experiments .. " of " .. NUM_CYCLES .. " false negative.")
    if num_experiments ~= 0 then
      error("Test failed!")
    end
    print("OK")

    -- next iteration counter
    table_size = get_next_iteration(table_size)
  end

  print(("Time: %.3f s (fast test)"):format(os_clock() - start))
end)

--------------------------------------------------------------------------------

test:group "validate_probability_precise"

--------------------------------------------------------------------------------

test 'validate_probability_precise-input' (function()
  print("Wrong inputs:")
  ensure_fails_with_substring(
      "wrong arguments",
      function() validate_probability_precise("a") end,
      "expected `table', got `string'"
    )
  ensure_fails_with_substring(
      "wrong arguments",
      function() validate_probability_precise({1, 2, "c"}, function() end) end,
      "`number' expected, got `string'"
    )
  ensure_fails_with_substring(
      "wrong arguments",
      function() validate_probability_precise({1, 2, 3}, function() end) end,
      "`table' expected, got `nil'"
    )
  local res, err = validate_probability_precise({1, 2, 0.9e-5}, function() end)
  if err ~= nil then print(err) else error("wrong input") end
end)

--------------------------------------------------------------------------------

do
  -- generates table, containing set of contrats weights (not normalized)
  local generate_contrast_weights = function(
      length, -- length of generated table
      power, -- 10^power high weight value
      are_low_rare -- if true table has single value = 1 and other = 10^power
    )
    local weights = {}
    local powered = 10 ^ power

    -- filling table
    if are_low_rare then
      weights = tgenerate_n(length, invariant(powered))
    else
      weights = tgenerate_n(length, invariant(1))
    end

    -- adding random rare value
    if are_low_rare then
      weights[math_random(length)] = 1
    else
      weights[math_random(length)] = powered
    end

    return weights
  end

  local weights_closure = {}
  -- is passed to validate_probability_precise
  local generate_experiments_defined = function(num_experiments)
    return generate_experiments(num_experiments, weights_closure)
  end

  -- checks validate_probability_precise work
  local check = function(weights, expermiments_fn, is_data_true, do_not_output)
    local res, err = validate_probability_precise(weights, expermiments_fn)
    if is_data_true ~= res or err ~= nil then
      if err ~= nil then print(err) end
      error("Failed!")
    else
      if not do_not_output then
        if is_data_true then
          print("OK - (no false negative)")
        else
          print("OK - (no false positive)")
        end
      end
    end
  end

  test 'validate_probability_precise-simple1' (function()
    weights_closure = {0.45, 0.55}
    check(weights_closure, generate_experiments_defined, true, true)
    check({0.5, 0.5}, generate_experiments_defined, false, true)
  end)

  test 'validate_probability_precise-simple2' (function()
    weights_closure = {0.3, 0.6, 0.1}
    check(weights_closure, generate_experiments_defined, true, true)
    check({0.275, 0.625, 0.1}, generate_experiments_defined, false, true)
  end)

  test 'validate_probability_precise-simple3' (function()
    weights_closure = {0.2, 0.2, 0.2, 0.2}
    check(weights_closure, generate_experiments_defined, true, true)
    check({0.22, 0.19, 0.19, 0.2}, generate_experiments_defined, false, true)
  end)

  test 'validate_probability_precise-simple4' (function()
    weights_closure = {0.1, 0.15, 0.2, 0.25, 0.3}
    check(weights_closure, generate_experiments_defined, true, true)
    check(
        {0.09, 0.15, 0.2, 0.25, 0.301},
        generate_experiments_defined,
        false,
        false
      )
  end)

  test 'validate_probability_precise-complex' (function()
    if test:in_strict_mode() then
      local start = os_clock()
      local i = START_POINT
      while i <= END_POINT do
        print("\nTable size: " .. i)
        print("random:")
        -- random correct input check
        weights_closure = generate_weights(i)
        check(weights_closure, generate_experiments_defined, true)

        -- random false input check
        local weights_closure_false = generate_weights(i)
        check(weights_closure_false, generate_experiments_defined, false)

        -- contrast correct input
        print("contrast:")
        -- for full test use 1, 5
        for j = 1, 3 do
          print("1 and " .. i - 1 .. " of 10^" .. j)
          weights_closure = generate_contrast_weights(i, j, true)
          check(weights_closure, generate_experiments_defined, true)

          if i > 2 then
            print(i - 1 .. " of 1 and 10^" .. j)
            weights_closure = generate_contrast_weights(i, j, false)
            check(weights_closure, generate_experiments_defined, true)
          end
        end

        -- contrast false input
        -- for full test use 1, 4
        for j = 1, 2 do
          print("1 and " .. i - 1 .. " of 10^" .. j .. ", added +" .. i)
          weights_closure = generate_contrast_weights(i, j, true)

          -- create wrong weights (by adding small value) and check
          local weights_closure_false = tclone(weights_closure)
          local ran_key = math_random(i)
          weights_closure_false[ran_key] = weights_closure_false[ran_key] + i
          check(weights_closure_false, generate_experiments_defined, false)

          if i > 2 then
            print(i - 1 .. " of 1 and 10^" .. j .. ", +" .. i)
            weights_closure = generate_contrast_weights(i, j, false)

            -- create wrong weights (by adding small value) and check
            weights_closure_false = tclone(weights_closure)
            ran_key = math_random(i)
            weights_closure_false[ran_key] = weights_closure_false[ran_key] + i
            check(weights_closure_false, generate_experiments_defined, false)
          end
        end

        -- next iteration counter
        i = get_next_iteration(i)
      end
      print(("Time: %.3f s (slow test)"):format(os_clock() - start))
    else
      print("Test skipped because strict mode is disabled.")
    end
  end)
end

--------------------------------------------------------------------------------

assert(test:run())
