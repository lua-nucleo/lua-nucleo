--------------------------------------------------------------------------------
--- Lua type assertions
-- @module lua-nucleo.typeassert
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local type, pairs, error, tostring = type, pairs, error, tostring

local lua51_types = import 'lua-nucleo/language.lua' { 'lua51_types' }

local result =
{
  assert_is_type = function(val, msg)
    return (lua51_types[val] == true)
       and val
        or error(
             (msg or "assertion failed")
             .. ": bad typename `" .. tostring(val) .. "'",
             2
           )
  end;

  assert_is_self = function(val, msg)
    return (type(val) == "table")
       and val
        or error(
             (msg or "assertion failed")
             .. ": bad self (got `" .. type(val) .. "'); use `:'",
             2
           )
  end;

  assert_is_nil = function(val, msg)
    return (val ~= nil) -- Note reverse order
       and error(
             (msg or "assertion failed")
             .. ": `nil' expected, got `" .. type(val) .. "'",
             2
           )
        or nil
  end;

  assert_is_boolean = function(val, msg)
    return (val ~= false and val ~= true) -- Note reverse order
       and error(
             (msg or "assertion failed")
             .. ": `boolean' expected, got `" .. type(val) .. "'",
             2
           )
        or val
  end;

  assert_not_nil = function(v, m, ...)
    if v == nil then
      error(m, 2)
    end
    return v, m, ...
  end
}

for type_name, _ in pairs(lua51_types) do
  local assert_name = "assert_is_"..type_name
  if not result[assert_name] then

    result[assert_name] = function(val, msg)
      return (type(val) == type_name)
         and val
          or error(
             (msg or "assertion failed")
             .. ": `" .. type_name .. "' expected, got `" .. type(val) .. "'",
             2
           )
    end

  end
end

return result
