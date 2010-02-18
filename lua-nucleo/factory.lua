-- factory.lua: factory related functions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local common_method_list = function(factory, ...)
  assert(type(factory) == "function", "`function' expected")
  local factory_return = factory(...)
  assert(type(factory_return) == "table", "`table' expected")
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
