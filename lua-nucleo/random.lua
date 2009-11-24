-- random.lua: tests for various common algorithms
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

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

local taccumulate,
      tnormalize
      = import 'lua-nucleo/table.lua'
      {
        'taccumulate',
        'tnormalize'
      }

local arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments'
      }

-- Function roughly determines if distribution of values in table t_stats
-- corresponds distribution in t_weights. Max number of elements check - 100.
-- Algorythm based on Hi square Pirson's test.
local ensure_probability_rough = function(t_weights, t_stats)

  -- input checks
  arguments(
    "table", t_weights,
    "table", t_stats
  )
  local n_length = 0
  for k, v in pairs(t_weights) do
    if type(t_weights[k]) ~= "number" or type(t_weights[k]) ~= "number" then
      error("Found non-numeric value in ensure_probability_rough function" ..
            "input tables. Key: " .. k
           )
    end
    n_length = n_length + 1
  end
  if n_length > 100 or n_length < 2 then
    error("Found wrong input table length in ensure_probability_rough " ..
          "function. Max length: 100, min length: 2 got: " .. n_length
         )
  end
  local n_experiments = taccumulate(t_stats)
  if n_experiments < 1000 then
    print("Lack of experiments data! Got experiments: ".. n_experiments ..
          ", need > 1000. Results may be false negative.")
  end

  -- main algorythm value, got 99% chance of false negative
  -- (though high chance of false positive accordingly)
  local t_hi_critical =
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

  -- data preparation
  local t_distribution_normalized = tnormalize(t_weights)
  local t_experiments_normalized = tnormalize(t_stats)
  local d_hi_square = 0

  -- algorythm itself
  for k, v in pairs(t_distribution_normalized) do
    local d_delta = math.abs(t_distribution_normalized[k] -
                             t_experiments_normalized[k])
    d_hi_square = d_hi_square + (100 * d_delta * d_delta) /
                  t_distribution_normalized[k]
  end

  return d_hi_square < t_hi_critical[n_length - 1]
end

-- Function precisely determines if distribution of values in table t_stats
-- corresponds distribution in t_weights.
-- Algorythm based on experiment probability check.
local ensure_probability_experiment = function(t_weights, f_stats_generator)
  -- input checks
  arguments(
    "table", t_weights,
    "function", f_stats_generator
  )
  for k, v in pairs(t_weights) do
    if type(t_weights[k]) ~= "number" or type(t_weights[k]) ~= "number" then
      error("Found non-numeric value in ensure_probability_experiment" ..
            "input tables. Key: " .. k
           )
    end
  end

  -- data preparation
  local t_distribution_normalized = tnormalize(t_weights)
  local n_start = 3
  local n_stop = 5
  local t_hi_square = {}
  local n_counter = 1
  local n_true = 0
  local n_sensitivity = 0
  local n_increased = 0
  local n_decreased = 0

  -- algorythm itself
  while true do
    -- check if we can return
    -- experience has shown that 8 value works ok
    -- more means less chances to fail, but more time to work
    local n_return_value = 8
    if n_true >= n_return_value then return true
    elseif n_true <= -n_return_value then return false end

    -- exponential experiments cycle: 10^n
    for n = n_start, n_stop do
      -- data peparation
      local t_cur_stats = f_stats_generator(math.pow(10, n))
      local n_experiments = math.pow(10, n)
      local t_experiments_normalized = tnormalize(t_cur_stats)

      -- calculate hi_square for current experiments num
      t_hi_square[n] = 0;
      for k, v in pairs(t_distribution_normalized) do
        local d_delta = math.abs(v - t_experiments_normalized[k])
        t_hi_square[n] = t_hi_square[n] + (100 * d_delta * d_delta) / v
      end
    end

    local d_temp_overal = t_hi_square[n_start] / t_hi_square[n_stop]
    local d_temp_first = t_hi_square[n_start] / t_hi_square[n_start + 1]
    local d_temp_last = t_hi_square[n_stop - 1] / t_hi_square[n_stop]

    -- TEMP! neat debug output, delete if found and do not know what it for
    --> print(n_true, d_temp_first, d_temp_last, d_temp_overal)

    -- check signs of definite hi_square dynamics
    if d_temp_overal > 90 then n_true = n_true + 1 end
    if d_temp_last > 9 and d_temp_first > 1 then n_true = n_true + 1  end
    if d_temp_first > 9 and d_temp_last > 1 then n_true = n_true + 1  end
    if d_temp_first > 1.2 then
      n_increased = n_increased + 1
      n_decreased = 0
    else
      n_decreased = n_decreased + 1
      n_increased = 0
    end
    if d_temp_last > 1.2 then
      n_increased = n_increased + 1
      n_decreased = 0
    else
      n_decreased = n_decreased + 1
      n_increased = 0
    end
    if n_increased >= 6 then n_true = n_true + 1 end
    if n_decreased >= 4 then n_true = n_true - 1 end

    if d_temp_overal > 0.25 and d_temp_overal < 4 then n_true = n_true - 1 end
    if d_temp_last > 0.5 and d_temp_last < 2 then n_true = n_true - 1 end
    if d_temp_first > 0.5 and d_temp_first < 2 then n_true = n_true - 1 end

    n_counter = n_counter + 1

    if n_counter > n_return_value * (0.5 + n_sensitivity) then
     -- TEMP! debug output, delete if found and do not know what it for
     --> print "Below level of sensitivity"
     if n_sensitivity > 2 then
        -- TODO: may be we need error here, due to uncertain output
        return n_true > 0
     end
     n_start = n_start + 1
     n_stop = n_stop + 1
     n_counter = 0
     n_sensitivity = n_sensitivity + 1
    end
  end
end

return
{
  ensure_probability_rough = ensure_probability_rough;
  ensure_probability_experiment = ensure_probability_experiment;
}