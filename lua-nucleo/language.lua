--------------------------------------------------------------------------------
--- Lua language data
-- @module lua-nucleo.language
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local lua51_keywords =
{
  ["and"] = true,    ["break"] = true,  ["do"] = true,
  ["else"] = true,   ["elseif"] = true, ["end"] = true,
  ["false"] = true,  ["for"] = true,    ["function"] = true,
  ["if"] = true,     ["in"] = true,     ["local"] = true,
  ["nil"] = true,    ["not"] = true,    ["or"] = true,
  ["repeat"] = true, ["return"] = true, ["then"] = true,
  ["true"] = true,    ["until"] = true,  ["while"] = true
}

local lua52_keywords = { ["goto"] = true }
for k, _ in pairs(lua51_keywords) do
  lua52_keywords[k] = true
end

local lua51_types =
{
  ["nil"] = true;
  ["boolean"] = true;
  ["number"] = true;
  ["string"] = true;
  ["table"] = true;
  ["function"] = true;
  ["thread"] = true;
  ["userdata"] = true;
}

local language =
{
  lua51_keywords = lua51_keywords;
  lua52_keywords = lua52_keywords;
  lua53_keywords = lua52_keywords;
  lua54_keywords = lua52_keywords;

  lua51_types = lua51_types;
  lua52_types = lua51_types;
  lua53_types = lua51_types;
  lua54_types = lua51_types;
}

for m = 1, 4 do
  m = tostring(m)
  if _VERSION == 'Lua 5.' .. m then
    language.lua_types = language['lua5' .. m .. '_types']
    language.lua_keywords = language['lua5' .. m .. '_keywords']
    break
  end
end

if not language.lua_types then
  error('Unsupported Lua version: ' .. tostring(_VERSION))
end

return language
