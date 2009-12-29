-- factory.lua -- factory related functions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local assert_is_table,
      assert_is_string,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_string',
        'assert_is_function'
      }

-- return list of factory methods
local common_method_list = function(factory, ...)
  assert_is_function(factory)
  local factory_return = factory(...)
  assert_is_table(factory_return)
  local method_list = {}
  for k, v in pairs(factory_return) do
    assert_is_string(k)
    if k:sub(-1) ~= '_' then
      method_list[#method_list + 1] = factory_return.k
    end
  end
  return method_list
end

return
{
  common_method_list = common_method_list;
}
