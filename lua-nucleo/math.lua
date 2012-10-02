--------------------------------------------------------------------------------
--- Math-related utilities
-- @module lua-nucleo.math
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local math_ceil, math_floor = math.ceil, math.floor

-- See http://en.wikipedia.org/wiki/Machine_epsilon
-- Depends on how Lua is built
local EPSILON = 2^-53     -- max { x | 1 + x == 1 }

--
-- Drops fractional part of a number
--
-- trunc(1.x)  -->  1
-- trunc(-1.x) --> -1
--
-- ceil(1.x)   -->  2
-- ceil(-1.x)  --> -1
--
-- floor(1.x)  -->  1
-- floor(-1.x) --> -2
--
-- TODO: Why not 'return (math.modf(n))'? Do benchmark.
local trunc = function(n)
  return ((n < 0) and math_ceil or math_floor)(n)
end

--- Compare arguments lhs and rhs for equality up to epsilon.
-- @param lhs left-hand side
-- @param rhs rigth-hand side
-- @param epsilon relative error epsilon
-- @return boolean type true if arguments lhs and rhs equal up epsilon, otherwise return false 
local epsilon_equals = function(lhs, rhs, epsilon)
  return lhs > rhs - epsilon
    and lhs < rhs + epsilon
end

return
{
  EPSILON = EPSILON;
  trunc = trunc;
  epsilon_equals = epsilon_equals;
}
