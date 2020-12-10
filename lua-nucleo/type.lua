--------------------------------------------------------------------------------
--- Lua type manipulation
-- @module lua-nucleo.type
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local type, pairs, assert = type, pairs, assert

local lua_types = import 'lua-nucleo/language.lua' { 'lua_types' }

local type_aliases =
{
  ["self"] = "is_table";
}

local result =
{
  is_type = function(v) return lua_types[v] == true end;
}

for type_name, _ in pairs(lua_types) do
  result["is_"..type_name] = function(v) return type(v) == type_name end
end

for alias, fn_name in pairs(type_aliases) do
  result["is_"..alias] = assert(result[fn_name])
end

return result
