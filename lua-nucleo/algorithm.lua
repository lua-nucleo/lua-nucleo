--------------------------------------------------------------------------------
--- Various common algorithms
-- @module lua-nucleo.algorithm
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert, pairs, ipairs = assert, pairs, ipairs
local math_floor, math_random = math.floor, math.random

local lower_bound = function(t, k, value)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if v < value then
      first = middle + 1
      len = len - half - 1
    else
      len = half
    end
  end
  return first
end

local lower_bound_pred = function(t, k, value, less)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if less(v, value) then
      first = middle + 1
      len = len - half - 1
    else
      len = half
    end
  end
  return first
end

local lower_bound_gt = function(t, k, value)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if v > value then
      first = middle + 1
      len = len - half - 1
    else
      len = half
    end
  end
  return first
end

local upper_bound = function(t, k, value)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if value < v then
      len = half
    else
      first = middle + 1
      len = len - half - 1
    end
  end
  return first
end

local upper_bound_pred = function(t, k, value, less)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if less(value, v) then
      len = half
    else
      first = middle + 1
      len = len - half - 1
    end
  end
  return first
end

local upper_bound_gt = function(t, k, value)
  local len = #t
  local first = 1
  local middle, half
  while len > 0 do
    half = math_floor(len / 2)
    middle = first + half
    local v = assert(
        assert(t[middle], "hole in array", middle)[k],
        "value missing"
      )
    if value > v then
      len = half
    else
      first = middle + 1
      len = len - half - 1
    end
  end
  return first
end

local pick_one = function(data)
  local result = nil

  local keys = data.keys
  local probs = data.probs

  local pos = math_random() * data.prob_sum
  for k, v in ipairs(probs) do -- TODO: Use binary search (lower_bound)!
    if pos <= v then
      result = keys[k]
      break
    end
  end

  return result
end

local pick_init = function(probs)
  local norm_probs = { }
  local key_index = { }
  local prob_sum = 0.0

  for key, prob in pairs(probs) do
    if prob > 0 then
      local i = #norm_probs + 1
      prob_sum = prob_sum + prob
      norm_probs[i] = prob_sum
      key_index[i] = key
    end
  end

  return
  {
    probs = norm_probs;
    keys = key_index;
    prob_sum = prob_sum;
  }
end

return
{
  lower_bound = lower_bound;
  lower_bound_pred = lower_bound_pred;
  lower_bound_gt = lower_bound_gt;
  --
  upper_bound = upper_bound;
  upper_bound_pred = upper_bound_pred;
  upper_bound_gt = upper_bound_gt;
  --
  pick_init = pick_init;
  pick_one = pick_one;
}
