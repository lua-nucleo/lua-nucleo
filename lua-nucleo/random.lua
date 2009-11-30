-- random.lua: utilities for random generation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local assert_is_number,
      assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_table'
      }

local ensure,
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
      }

local taccumulate,
      tnormalize,
      tcount_elements
      = import 'lua-nucleo/table.lua'
      {
        'taccumulate',
        'tnormalize',
        'tcount_elements'
      }

local arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments'
      }

local type_imports = import 'lua-nucleo/type.lua' ()

local math_abs = math.abs
local pairs = pairs

-- main algorithm value, got 99% chance of false negative
-- (though high chance of false positive accordingly)
-- http://www.itl.nist.gov/div898/handbook/eda/section3/eda3674.htm
local CHI_CRITICAL_LIST =
{
  006.635; 009.210; 011.345; 013.277; 015.086; 016.812; 018.475; 020.090;
  021.666; 023.209; 024.725; 026.217; 027.688; 029.141; 030.578; 032.000;
  033.409; 034.805; 036.191; 037.566; 038.932; 040.289; 041.638; 042.980;
  044.314; 045.642; 046.963; 048.278; 049.588; 050.892; 052.191; 053.486;
  054.776; 056.061; 057.342; 058.619; 059.893; 061.162; 062.428; 063.691;
  064.950; 066.206; 067.459; 068.710; 069.957; 071.201; 072.443; 073.683;
  074.919; 076.154; 077.386; 078.616; 079.843; 081.069; 082.292; 083.513;
  084.733; 085.950; 087.166; 088.379; 089.591; 090.802; 092.010; 093.217;
  094.422; 095.626; 096.828; 098.028; 099.228; 100.425; 101.621; 102.816;
  104.010; 105.202; 106.393; 107.583; 108.771; 109.958; 111.144; 112.329;
  113.512; 114.695; 115.876; 117.057; 118.236; 119.414; 120.591; 121.767;
  122.942; 124.116; 125.289; 126.462; 127.633; 128.803; 129.973; 131.141;
  132.309; 133.476; 134.642;
}

-- Function roughly determines if distribution of values in table experiments
-- corresponds distribution in weights. Max number of elements check - 100.
-- algorithm based on Hi square Pearson's test.
-- http://en.wikipedia.org/wiki/Pearson%27s_chi-square_test
local validate_probability_rough = function(weights, experiments)
  -- input checks
  arguments(
    "table", weights,
    "table", experiments
  )
  local length = 0
  for k, v in pairs(weights) do
    assert_is_number(weights[k])
    assert_is_number(experiments[k])
    length = length + 1
  end
  if length > 100 or length < 2 then
    return nil, "argument: wrong weight table size"
  end
  if tcount_elements(experiments) ~= length then
    return nil, "argument: wrong experiments table size"
  end
  local experiments_num = taccumulate(experiments)
  if experiments_num < 1000 then
    return nil, "argument: lack of experiments data"
  end

  -- data preparation
  local weights_normalized = tnormalize(weights)
  local experiments_normalized = tnormalize(experiments)
  local chi_square = 0

  -- algorithm itself
  for k, v in pairs(weights_normalized) do
    local delta = math_abs(weights_normalized[k] - experiments_normalized[k])
    chi_square = chi_square + (100 * delta * delta) / weights_normalized[k]
  end

  return chi_square < CHI_CRITICAL_LIST[length - 1]
end

-- Function precisely determines if distribution of values in table experiments
-- corresponds distribution in weights.
-- algorithm based on experiment probability check.
local validate_probability_precise = function(weights, generate)
  -- input checks
  arguments(
    "table", weights,
    "function", generate
  )
  for k, v in pairs(weights) do
    assert_is_number(weights[k])
  end
  local weights_normalized = tnormalize(weights)
  for k, v in pairs(weights_normalized) do
    if
      weights_normalized[k] < 1e-5
    then
      return nil, "Input weights below level of sensitivity"
    end
  end
  local test_table = generate(50)
  assert_is_table(test_table)
  for k, v in pairs(test_table) do
    assert_is_number(test_table[k])
  end
  if tcount_elements(test_table) ~= tcount_elements(weights) then
    return nil, "argument: wrong generated table size"
  end
  local experiments_num = taccumulate(test_table)
  if experiments_num ~= 50 then
    return nil, "argument: wrong generated table data"
  end

  -- various algorithm variables initialization
  local DECISION_VALUE = 8
  local BASE_SENSITIVITY = 3
  local SENSITIVITY_DELTA = 2
  local INCREASE_LIMIT = 2
  local sensitivity = BASE_SENSITIVITY -- power of number of experiments used
  local chi_squares = {} -- chi square container
  local iteration = 0 -- iteration counter
  local decision = 0 -- decision making value
  local tendency = 0

  -- algorithm itself
  while true do
    -- check if we can return
    -- experience has shown that 8 value works ok
    -- more means less chances to fail, but more time to work
    if decision >= DECISION_VALUE then return true
    elseif decision <= -DECISION_VALUE then return false end

    -- exponential experiments cycle: 10^n
    for n = 0, SENSITIVITY_DELTA do
      -- data preparation
      local experiments_num = 10 ^ (sensitivity + n)
      local experiments = generate(experiments_num)
      local experiments_normalized = tnormalize(experiments)

      -- calculate chi_square for current experiments num
      chi_squares[n] = 0;
      for k, v in pairs(weights_normalized) do
        local delta = math_abs(v - experiments_normalized[k])
        chi_squares[n] = chi_squares[n] + (100 * delta * delta) / v
      end
    end

    local overal_change = chi_squares[0] / chi_squares[SENSITIVITY_DELTA]
    local first_change = chi_squares[0] / chi_squares[1]
    local second_change = chi_squares[1] / chi_squares[SENSITIVITY_DELTA]

    -- TEMP! neat debug output, delete if found and do not know what it for
    --> print(decision, first_change, second_change, overal_change)

    -- check signs of definite chi_square dynamics
    -- all constants are test-based
    local OVERALL_IMPROVEMENT = 90
    local STEP_IMPROVEMENT = 9
    local STEP_STAGNATION_LOW = 0.5
    local STEP_STAGNATION_TOP = 2
    local STEP_STAGNATION = 1.2
    local OVERALL_STAGNATION_LOW = 0.25
    local OVERALL_STAGNATION_TOP = 4

    if overal_change > OVERALL_IMPROVEMENT then
      decision = decision + 1
    end
    if first_change > STEP_IMPROVEMENT and second_change > 1 then
      decision = decision + 1
    end
    if second_change > STEP_IMPROVEMENT and first_change > 1 then
      decision = decision + 1
    end
    if
      overal_change > OVERALL_STAGNATION_LOW and
      overal_change < OVERALL_STAGNATION_TOP
    then
      decision = decision - 1
    end
    if
      second_change > STEP_STAGNATION_LOW and
      second_change < STEP_STAGNATION_TOP
    then
      decision = decision - 1
    end
    if
      first_change > STEP_STAGNATION_LOW and
      first_change < STEP_STAGNATION_TOP
    then
      decision = decision - 1
    end
    if second_change > STEP_STAGNATION then
      if tendency < 0 then tendency = 0 end
      tendency = tendency + 1
    else
      if tendency > 0 then tendency = 0 end
      tendency = tendency - 1
    end
    if first_change > STEP_STAGNATION then
      if tendency < 0 then tendency = 0 end
      tendency = tendency + 1
    else
      if tendency > 0 then tendency = 0 end
      tendency = tendency - 1
    end

    -- 6 and -4 are algorithm magic constants
    if tendency >= 6 then decision = decision + 1 end
    if tendency <= -4 then decision = decision - 1 end

    iteration = iteration + 1

    -- we are too deep, and accuracy is too high, experiments matches weights
    if
      sensitivity == BASE_SENSITIVITY + INCREASE_LIMIT - 1
      and chi_squares[SENSITIVITY_DELTA] < 1e-5
    then
      return true
    end

    if iteration > DECISION_VALUE * (0.5 + sensitivity - BASE_SENSITIVITY) then
      -- TEMP! debug output, delete if found and do not know what it for
      --> print("Below level of sensitivity " .. sensitivity)
      if
        sensitivity >= BASE_SENSITIVITY + INCREASE_LIMIT
      then
        return nil, "Below level of sensitivity"
      end
      sensitivity = sensitivity + 1
    end
  end
end

return
{
  validate_probability_rough = validate_probability_rough;
  validate_probability_precise = validate_probability_precise;
}
