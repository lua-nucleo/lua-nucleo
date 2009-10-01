-- misc.lua: various useful stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local unique_object = function()
  -- newproxy() would be faster, but it is undocumented.
  -- Note that table is not acceptable, since its contents are not constant.
  return function() end
end

return
{
  unique_object = unique_object;
}
