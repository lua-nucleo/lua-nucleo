-- string.lua: string-related tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local table_concat, table_insert = table.concat, table.insert
local string_find, string_sub = string.find, string.sub
local assert, pairs = assert, pairs

local make_concatter -- TODO: rename, is not factory
do
  make_concatter = function()
    local buf = {}

    local function cat(v)
      buf[#buf + 1] = v
      return cat
    end

    local concat = function(glue)
      return table_concat(buf, glue or "")
    end

    return cat, concat
  end
end

-- Remove trailing and leading whitespace from string.
-- From Programming in Lua 2 20.4
local trim = function(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- TODO: Rename! (urlencode?)
local escape_string = function(str)
  return str:gsub(
      "[%c]",
      function(c)
        return ("%%%02X"):format(c:byte())
      end
    )
end

local htmlspecialchars = nil
do
  local subst =
  {
    ["&"] = "&amp;";
    ['"'] = "&quot;";
    ["'"] = "&apos;";
    ["<"] = "&lt;";
    [">"] = "&gt;";
  }

  htmlspecialchars = function(value)
    return (value:gsub("[&\"'<>]", subst))
  end
end

local cdata_wrap = function(value)
  -- "]]>" is escaped as ("]]" + "]]><![CDATA[" + ">")
  return '<![CDATA[' .. value:gsub("]]>", ']]]]><![CDATA[>') .. ']]>'
end

local cdata_cat = function(cat, value)
  -- "]]>" is escaped as ("]]" + "]]><![CDATA[" + ">")
  cat '<![CDATA[' (value:gsub("]]>", ']]]]><![CDATA[>')) ']]>'
end

-- TODO: Looks ugly and slow. Rewrite.
-- Based on http://lua-users.org/wiki/MakingLuaLikePhp
local split_by_char = function(str, div)
  local result = false
  if div ~= "" then
    local pos = 0
    result = {}

    if str ~= "" then
      -- for each divider found
      for st, sp in function() return string_find(str, div, pos, true) end do
        -- Attach chars left of current divider
        table_insert(result, string_sub(str, pos, st - 1))
        pos = sp + 1 -- Jump past current divider
      end
      -- Attach chars right of last divider
      table_insert(result, string_sub(str, pos))
    end
  end
  return result
end

local count_substrings = function(str, substr)
  local count = 0

  local s, e = 0, 0
  while true do
    s, e = str:find(substr, e + 1, true)
    if s ~= nil then
      count = count + 1
    else
      break
    end
  end

  return count
end

local split_by_offset = function(str, offset, skip_right)
  assert(offset <= #str)
  return str:sub(1, offset), str:sub(offset + 1 + (skip_right or 0))
end

local fill_placeholders_ex = function(capture, str, dict)
  return (str:gsub("%$%((.-)%)", dict))
end

local fill_placeholders = function(str, dict)
  return fill_placeholders_ex("%$%((.-)%)", str, dict)
end

local fill_curly_placeholders = function(str, dict)
  return fill_placeholders_ex("%${(.-)}", str, dict)
end

local kv_concat = function(t, kv_glue, pair_glue, pairs_fn)
  pair_glue = pair_glue or ""
  pairs_fn = pairs_fn or pairs

  local cat, concat = make_concatter()
  local glue = ""
  for k, v in pairs_fn(t) do
    cat (glue) (k) (kv_glue) (v)
    glue = pair_glue
  end
  return concat()
end

local escape_lua_pattern
do
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
  }

  escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
  end
end

return
{
  escape_string = escape_string;
  make_concatter = make_concatter;
  trim = trim;
  htmlspecialchars = htmlspecialchars;
  fill_placeholders_ex = fill_placeholders_ex;
  fill_placeholders = fill_placeholders;
  fill_curly_placeholders = fill_curly_placeholders;
  cdata_wrap = cdata_wrap;
  cdata_cat = cdata_cat;
  split_by_char = split_by_char;
  split_by_offset = split_by_offset;
  count_substrings = count_substrings;
  kv_concat = kv_concat;
  escape_lua_pattern = escape_lua_pattern;
}
