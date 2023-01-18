-- luacheck: globals import

local is_function = import 'lua-nucleo/type.lua' { 'is_function' }

local maybe_call = function(fn, ...)
  if is_function(fn) then
    return fn(...)
  end

  return fn, ...
end

return
{
  maybe_call = maybe_call;
}
