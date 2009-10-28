-- string.lua: string-related tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local table_concat = table.concat

local make_concatter
do
  make_concatter = function()
    local buf = {}

    local function cat(v)
      buf[#buf + 1] = v
      return cat
    end

    local concat = function()
      return table_concat(buf, "")
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

local fill_placeholders = function(str, dict)
  return (str:gsub("%$%((.-)%)", dict))
end

return
{
  escape_string = escape_string;
  make_concatter = make_concatter;
  trim = trim;
  htmlspecialchars = htmlspecialchars;
  fill_placeholders = fill_placeholders;
}
