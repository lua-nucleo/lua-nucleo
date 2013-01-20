--------------------------------------------------------------------------------
--- Factory related functions
-- @module lua-nucleo.factory
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local common_method_list = function(factory, ...)
  arguments(
      "function", factory
    )

  local factory_return = factory(...)
  assert_is_table(factory_return)
  local method_list = {}
  for k, v in pairs(factory_return) do
    if type(v) == "function" then
      if type(k) == "string" then
        if k:sub(-1) ~= '_' then
          method_list[#method_list + 1] = k
        end
      else
        error("non-string key for function value")
      end
    end
  end
  return method_list
end

return
{
  common_method_list = common_method_list;
}
