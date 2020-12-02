--------------------------------------------------------------------------------
--- Utils that deal with function arguments
-- @module lua-nucleo.args
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Separate arguments() and method_arguments() to other module?

local lua_types = import 'lua-nucleo/language.lua' { 'lua_types' }

local type, select, error, tostring = type, select, error, tostring

local nargs = function(...)
  return select("#", ...), ...
end

local pack = function(...)
  return select("#", ...), { ... }
end

local eat_true = function(v, ...)
  if v ~= true then
    local msg = (...)
    if not v and type(msg) == "string" then
      error("can't eat true:\n"..msg, 2)
    else
      error("can't eat true, got "..tostring(v), 2)
    end
  end
  return ...
end

local amap
do
  local function impl(n, fn, a, ...)
    if n > 1 then
      return fn(a), impl(n - 1, fn, ...)
    end
    return fn(a)
  end

  amap = function(fn, ...)
    return impl(select("#", ...), fn, ...)
  end
end

local arguments, optional_arguments, method_arguments, check_types
do
  local function impl(is_optional, nargs, ...)
    -- Points error on function, calling function which calls *arguments()

    for i = 1, nargs, 2 do
      local expected_type, value = select(i, ...)

      if type(value) ~= expected_type then
        if not lua_types[expected_type] then
          error(
              "argument #" .. math.floor((i + 1) * 0.5)
              .. ": bad expected type `" .. tostring(expected_type) .. "'",
              3
            )
        end

        if not is_optional or value ~= nil then
          error(
              (is_optional and "optional " or "")
              .. "argument #" .. math.floor(((i + 1) * 0.5)) .. ": expected `"
              .. tostring(expected_type) .. "', got `" .. type(value) .. "'",
              3
            )
        end
      end
    end

  end

  arguments = function(...)
    local nargs = select('#', ...)
    if nargs > 0 then
      if nargs % 2 == 0 then
        impl(false, nargs, ...) -- Not optional
        return
      end
      error("arguments: bad call, dangling argument detected", 2)
    end
  end

  optional_arguments = function(...)
    local nargs = select('#', ...)
    if nargs > 0 then
      if nargs % 2 == 0 then
        impl(true, nargs, ...) -- Optional
        return
      end
      error("arguments: bad call, dangling argument detected", 2)
    end
  end

  method_arguments = function(self, ...)
    -- Points error on function, calling function which calls method_arguments()
    local nargs = select('#', ...)
    if type(self) ~= "table" then
      error("bad self (got `"..type(self).."'); use `:'", 3)
    elseif nargs > 0 then
      if nargs % 2 == 0 then
        impl(false, nargs, ...) -- Not optional
        return
      end
      error("arguments: bad call, dangling argument detected", 2)
    end
  end

  check_types = function(...)
    local args = { ... }
    if #args == 0 then
      return true
    end

    for i = 1, #args, 3 do
      local name, value_type, value = tostring(args[i]), tostring(args[i + 1]), args[i + 2]

      if type(value) ~= value_type then
        return nil, "Incorrect type for field " .. name .. ": required '" .. value_type .. "', have '" .. type(value) .. "'"
      end
    end

    return true
  end
end

return
{
  pack = pack;
  nargs = nargs;
  eat_true = eat_true;
  amap = amap;
  --
  arguments = arguments;
  optional_arguments = optional_arguments;
  method_arguments = method_arguments;
  check_types = check_types;
}
