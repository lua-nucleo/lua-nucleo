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

local arguments, method_arguments
do
  local function impl(arg_n, expected_type, value, ...)
    -- Points error on function, calling function which calls *arguments()
    if type(value) ~= expected_type then
      if not lua51_types[expected_type] then
        error(
            "argument #"..arg_n..": bad expected type `"..tostring(expected_type).."'",
            3 + arg_n
          )
      end
      error(
          "argument #"..arg_n..": expected `"..tostring(expected_type).."', got `"..type(value).."'",
          3 + arg_n
        )
    end

    -- If have at least one more type, check it
    return ((...) ~= nil) and impl(arg_n + 1, ...) or true
  end

  arguments = function(...)
    local nargs = select('#', ...)
    return (nargs > 0)
       and (
         (nargs % 2 == 0)
           and impl(1, ...)
            or error("arguments: bad call, dangling argument detected")
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
                  and impl(1, ...)
                   or error("method_arguments: bad call, dangling argument detected")
              )
              or true
          )
  end
end

return
{
  pack = pack;
  nargs = nargs;
  --
  arguments = arguments;
  method_arguments = method_arguments;
}
