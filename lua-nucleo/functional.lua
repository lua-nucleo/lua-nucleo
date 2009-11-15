-- functional.lua -- functional module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local do_nothing = function() end

local identity = function(...) return ... end

-- TODO: Backport advanced version with caching for primitive types
local invariant = function(v)
  return function()
    return v
  end
end

local create_table = function(...)
  return { ... }
end

local make_generator_mt = function(fn)
  return
  {
    __index = function(t, k)
      local v = fn(k)
      t[k] = v
      return v
    end;
  }
end

return
{
  do_nothing = do_nothing;
  identity = identity;
  invariant = invariant;
  create_table = create_table;
  make_generator_mt = make_generator_mt;
}
