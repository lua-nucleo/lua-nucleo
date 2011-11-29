-- args.lua: utils that deal with function arguments
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Separate arguments() and method_arguments() to other module?

local lua51_types = import 'lua-nucleo/language.lua' { 'lua51_types' }

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
  local function impl(is_optional, arg_n, expected_type, value, ...)
    -- Points error on function, calling function which calls *arguments()

    if type(value) ~= expected_type then
      if not lua51_types[expected_type] then
        error(
            "argument #"..arg_n..": bad expected type `"..tostring(expected_type).."'",
            3 + arg_n
          )
      end

      if not is_optional or value ~= nil then
        error(
            (is_optional and "optional " or "")
         .. "argument #"..arg_n..": expected `"..tostring(expected_type)
         .. "', got `"..type(value).."'",
            3 + arg_n
          )
      end
    end

    -- If have at least one more type, check it
    return ((...) ~= nil) and impl(is_optional, arg_n + 1, ...) or true
  end

  arguments = function(...)
    local nargs = select('#', ...)
    return (nargs > 0)
       and (
         (nargs % 2 == 0)
           and impl(false, 1, ...) -- Not optional
            or error("arguments: bad call, dangling argument detected", 2)
       )
       or true
  end

  optional_arguments = function(...)
    local nargs = select('#', ...)
    return (nargs > 0)
       and (
         (nargs % 2 == 0)
           and impl(true, 1, ...) -- Optional
            or error("arguments: bad call, dangling argument detected", 2)
       )
       or true
  end

  method_arguments = function(self, ...)
    -- Points error on function, calling function which calls method_arguments()
    local nargs = select('#', ...)
    return (type(self) ~= "table")
       and error("bad self (got `"..type(self).."'); use `:'", 3)
        or (
            (nargs > 0)
              and (
                (nargs % 2 == 0)
                  and impl(false, 1, ...) -- Not optional
                   or error("method_arguments: bad call, dangling argument detected", 2)
              )
              or true
          )
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
