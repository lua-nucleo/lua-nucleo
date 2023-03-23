--------------------------------------------------------------------------------
--- Various table ordering utilities
-- @module lua-nucleo.ordered_keys
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ordered_pairs = import 'lua-nucleo/tdeepequals.lua' { 'ordered_pairs' }

local keys_to_order = function(keys)
  local keys_to_order = { }

  for i = 1, #keys do
    keys_to_order[keys[i]] = i
  end

  return keys_to_order
end

local keys_less = function(key_order, pre_ordered)
  if not pre_ordered then
    key_order = keys_to_order(key_order)
  end

  local keys = setmetatable({ }, {
    __mode = 'k';
    __index = function(t, k)
      local v = k
      t[k] = v
      return v
    end
  })

  return function(lhs, rhs)
    lhs = keys[lhs]
    rhs = keys[rhs]

    local lhs_i = key_order[lhs] or math.huge
    local rhs_i = key_order[rhs] or math.huge

    if lhs_i ~= rhs_i then
      return lhs_i < rhs_i
    end

    return lhs < rhs
  end
end

local ordered_key_pairs = function(t, key_list, pre_ordered)
  return ordered_pairs(t, keys_less(key_list, pre_ordered))
end

return
{
  keys_to_order = keys_to_order;
  keys_less = keys_less;
  ordered_key_pairs = ordered_key_pairs;
}
