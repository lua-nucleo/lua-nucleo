--------------------------------------------------------------------------------
--- Lua language data
-- @module lua-nucleo.language
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- for documentation purposes only:
if false then
  --- Hashset of Lua 5.1 language keywords (table where the key is a keyword
  -- string and the value is the `true` boolean).
  local lua51_keywords = { }

  --- Hashset of Lua 5.2 language keywords (table where the key is a keyword
  -- string and the value is the `true` boolean).
  local lua52_keywords = { }

  --- Hashset of Lua 5.3 language keywords (table where the key is a keyword
  -- string and the value is the `true` boolean). Equals to `lua52_keywords`.
  local lua53_keywords = { }

  --- Hashset of Lua 5.4 language keywords (table where the key is a keyword
  -- string and the value is the `true` boolean). Equals to `lua52_keywords`.
  local lua54_keywords = { }

  --- Hashset of currently running Lua version types (table where the key is a
  -- keyword string and the value is the `true` boolean).
  local lua_keywords = { }

  --- Hashset of Lua 5.1 types (table where the key is the type name string and
  -- the value is the `true` boolean).
  local lua51_types = { }

  --- Hashset of Lua 5.2 types (table where the key is the type name string and
  -- the value is the `true` boolean). Equals to `lua51_types`.
  local lua52_types = { }

  --- Hashset of Lua 5.3 types (table where the key is the type name string and
  -- the value is the `true` boolean). Equals to `lua51_types`.
  local lua53_types = { }

  --- Hashset of Lua 5.4 types (table where the key is the type name string and
  -- the value is the `true` boolean). Equals to `lua51_types`.
  local lua54_types = { }

  --- Hashset of currently running Lua version types (table where the key is the
  -- type name string and the value is the `true` boolean).
  local lua_types = { }

  --- <code>true</code>, if running inside Lua 5.1 VM
  local is_lua51 = _VERSION == 'Lua 5.1'
  --- <code>true</code>, if running inside Lua 5.2 VM
  local is_lua52 = _VERSION == 'Lua 5.2'
  --- <code>true</code>, if running inside Lua 5.3 VM
  local is_lua53 = _VERSION == 'Lua 5.3'
  --- <code>true</code>, if running inside Lua 5.4 VM
  local is_lua54 = _VERSION == 'Lua 5.4'
end

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

local minor_version_start = 1
local minor_version_end = 4

for m = minor_version_start, minor_version_end do
  m = tostring(m)
  local is_on_m_version = _VERSION == 'Lua 5.' .. m
  language['is_lua5' .. m] = is_on_m_version
  if is_on_m_version then
    language.lua_types = language['lua5' .. m .. '_types']
    language.lua_keywords = language['lua5' .. m .. '_keywords']
    break
  end
end

if not language.lua_types then
  error('Unsupported Lua version: ' .. tostring(_VERSION))
end

return language
