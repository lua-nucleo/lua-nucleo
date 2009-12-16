-- functional.lua: (pseudo-)functional stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local assert, unpack = assert, unpack
local table_remove = table.remove

local assert_is_number,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_function'
      }

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

local arguments_ignorer = function(fn)
  return function()
    return fn()
  end
end

local list_caller = function(calls)
  return function()
    for i = 1, #calls do
      local call = calls[i]
      assert_is_function(call[1])(
          unpack(
              call,
              2,
              assert_is_number(
                  call.n or (#call - 1)
                ) + 1
            )
        )
    end
  end
end

return
{
  do_nothing = do_nothing;
  identity = identity;
  invariant = invariant;
  create_table = create_table;
  make_generator_mt = make_generator_mt;
  arguments_ignorer = arguments_ignorer;
  list_caller = list_caller;
}
