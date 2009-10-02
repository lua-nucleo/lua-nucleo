-- type.lua: Lua type manipulation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local type, pairs, assert = type, pairs, assert

local type_names =
{
  ["nil"] = true;
  ["number"] = true;
  ["string"] = true;
  ["boolean"] = true;
  ["table"] = true;
  ["function"] = true;
  ["thread"] = true;
  ["userdata"] = true;
}

local type_aliases =
{
  ["coroutine"] = "is_thread";
  ["bool"] = "is_boolean";
  ["self"] = "is_table";
}

local result =
{
  is_type = function(v) return type_names[v] == true end;
}

for type_name, _ in pairs(type_names) do
  result["is_"..type_name] = function(v) return type(v) == type_name end
end

for alias, fn_name in pairs(type_aliases) do
  result["is_"..alias] = assert(result[fn_name])
end

return result
