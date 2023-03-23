--------------------------------------------------------------------------------
--- Various table ordering utilities
-- @module lua-nucleo.ordered_keys
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ordered_pairs = import 'lua-nucleo/tdeepequals.lua' { 'ordered_pairs' }

--- Fill table values with keys indicies.
-- @tparam table keys Table with keys.
-- @treturn table keys_to_order Filled table.
-- @usage
-- keys_to_order({ 'a', 'b', 'c' })
-- returns { a = 1, b = 2, c = 3 }
local keys_to_order = function(keys)
  local keys_to_order = { }

  for i = 1, #keys do
    keys_to_order[keys[i]] = i
  end

  return keys_to_order
end

--- Create sort function for compare left and right side keys
-- by index stored in value of key_order table or compare
-- by itself if index does not exists for key.
-- @tparam table key_order Table using for compare keys.
-- @tparam[opt=false] boolean pre_ordered Indicates is key_order
-- table presorted with keys_to_order method.
-- @treturn function Sort function.
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

--- Create iterator for table t that sort table using keys_less method.
-- @tparam table t Table to sort.
-- @tparam table key_list See @{keys_less} for details.
-- @tparam[opt=false] boolean pre_ordered See @{keys_less} for details.
-- @return Iterator.
local ordered_key_pairs = function(t, key_list, pre_ordered)
  return ordered_pairs(t, keys_less(key_list, pre_ordered))
end

return
{
  keys_to_order = keys_to_order;
  keys_less = keys_less;
  ordered_key_pairs = ordered_key_pairs;
}
