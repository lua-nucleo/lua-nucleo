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

-- We want 99.9% probability of success
-- Would not work for high-contrast weights. Use for tests only.
local ensure_aposteriori_probability = function(num_runs, weights, stats, max_acceptable_diff)
  ensure_equals("total sum check", taccumulate(stats), num_runs)

  local apriori_probs = tnormalize(weights)
  local aposteriori_probs = tnormalize(stats)

  for k, apriori in pairs(apriori_probs) do
    local aposteriori = assert_is_number(aposteriori_probs[k])

    ensure("apriori must be positive", apriori > 0)
    ensure("aposteriori must be non-negative", aposteriori >= 0)

    -- TODO: Lame check. Improve it.
    local diff = math.abs(apriori - aposteriori) / apriori
    if diff > max_acceptable_diff then
      error(
          "inacceptable apriori-aposteriori difference key: `" .. tostring(k) .. "'"
          .. " num_runs: " .. num_runs
          .. " apriori: " .. apriori
          .. " aposteriori: " .. aposteriori
          .. " actual_diff: " .. diff
          .. " max_diff: " .. max_acceptable_diff
        )
    end

    aposteriori_probs[k] = nil -- To check there is no extra data below.
  end

  ensure_equals("no extra data", next(aposteriori_probs), nil)
end

return
{
  ensure_aposteriori_probability = ensure_aposteriori_probability;
}