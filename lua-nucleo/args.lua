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
    if type(value) ~= expected_type then
      if not lua51_types[expected_type] then
        error(
            "argument #"..arg_n..": bad expected type `"..tostring(expected_type).."'",
            2 + arg_n
          )
      end
      error(
          "argument #"..arg_n..": expected `"..tostring(expected_type).."', got `"..type(value).."'",
          2 + arg_n
        )
    end

    -- If have at least one more type, check it
    return ((...) ~= nil) and impl(arg_n + 1, ...)
  end

  arguments = function(...)
    return ((...) ~= nil) and impl(1, ...)
  end

  method_arguments = function(self, ...)
    return (type(self) ~= "table")
       and error("bad self (got `"..type(self).."'); use `:'", 2)
        or (((...) ~= nil) and impl(1, ...))
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
