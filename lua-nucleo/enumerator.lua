--------------------------------------------------------------------------------
--- Enuminator tools
-- @module lua-nucleo.enumerator
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Refactor!

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

--- Returns minimum value.
-- @function enuminator.get_first
-- @tparam enuminator self
-- @treturn number Minimum value
-- @local
local get_first = function(self)
  method_arguments(self)
  return self.min_value_
end

--- Returns next value for the given value.
-- @function enuminator.get_next
-- @tparam enuminator self
-- @tparam number value
-- @treturn[1] number Next value.
-- @treturn[2] nil If value is bigger than the maximum.
-- @raise Error if no next value is found.
-- @local
local get_next = function(self, value)
  method_arguments(
    self,
    "number", value
  )
  if value <= self.min_value_ then return self.min_value_ end
  if value  > self.max_value_ then return nil end
  return assert(self.next_values_[value])
end

--- Checks if the value has the next value.
-- @function enuminator.contains
-- @tparam enuminator self
-- @tparam number value
-- @treturn boolean True, if <code>self</code> contains.
-- @local
local contains = function(self, value)
  method_arguments(
    self,
    "number", value
  )
  return value >= self.min_value_ and value <= self.max_value_
    and self.next_values_[value] == value
end

--- Makes enumerator from set.
-- @tparam number[] values
-- @treturn enuminator instance.
local make_enumerator_from_set = function(values)
  arguments(
    "table", values
  )

  local next_values
  do
    next_values = { }
    local curr_index = 1
    for i = values[1], values[#values] do
      if i > values[curr_index] then curr_index = curr_index + 1 end
      assert(i <= values[curr_index])
      next_values[i] = values[curr_index]
    end
  end

  return
  {
    get_first = get_first;
    get_next = get_next;
    contains = contains;
    --
    values_ = values;
    min_value_ = values[1];
    max_value_ = values[#values];
    next_values_ = next_values;
  }
end

--- Makes enumerator based on the passed interval boundaries with a step of 1.
-- @tparam number first Interval start.
-- @tparam number last Interval end.
-- @treturn enuminator instance.
local make_enumerator_from_interval = function(first, last)
  arguments(
    "number", first,
    "number", last
  )
  local values = {}
  for i = first, last do values[#values + 1] = i end
  return make_enumerator_from_set(values)
end

return
{
  make_enumerator_from_set = make_enumerator_from_set;
  make_enumerator_from_interval = make_enumerator_from_interval;
}
