--------------------------------------------------------------------------------
-- functional.lua: (pseudo-)functional stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert, unpack, select = assert, unpack, select
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

local bind_many = function(fn, ...)
  local n, args = select("#", ...), { ... }
  return function()
    return fn(unpack(args, 1, n))
  end
end

local remove_nil_arguments
do
  local function impl(n, a, ...)
    if n > 0 then
      if a ~= nil then
        return a, impl(n - 1, ...)
      end

      return impl(n - 1, ...)
    end
  end

  remove_nil_arguments = function(...)
    return impl(select("#", ...), ...)
  end
end

local args_proxy = function(fn, ...)
  fn(...)
  return ...
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
  bind_many = bind_many;
  remove_nil_arguments = remove_nil_arguments;
  args_proxy = args_proxy;
}
