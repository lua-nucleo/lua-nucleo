-- assert.lua: enhanced assertions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local error = error

local lassert = function(level, cond, msg, ...)
  if cond then
    return cond, msg, ...
  end
  error(msg, level + 1)
end

return
{
  lassert = lassert;
}
