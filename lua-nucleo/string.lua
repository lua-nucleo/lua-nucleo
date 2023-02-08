--------------------------------------------------------------------------------
--- String-related tools
-- @module lua-nucleo.string
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local table_concat, table_insert = table.concat, table.insert
local math_floor, math_huge = math.floor, math.huge
local string_find, string_sub, string_format = string.find, string.sub, string.format
local string_byte, string_char = string.byte, string.char
local assert, pairs, type = assert, pairs, type

local tidentityset,
      tisarray,
      tkeys
      = import 'lua-nucleo/table-utils.lua'
      {
        'tidentityset',
        'tisarray',
        'tkeys'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local setfenv = import 'lua-nucleo/compatibility.lua' { 'setfenv' }

local make_concatter -- TODO: rename, is not factory
do
  make_concatter = function()
    local buf = { }

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

local create_escape_subst = function(string_subst, ignore)
  ignore = ignore or { "\n", "\t" }
  local subst = setmetatable(
      tidentityset(ignore),
      {
        __metatable = "escape.char";
        __index = function(t, k)
          local v = (string_subst):format(k:byte())
          t[k] = v
          return v
        end;
      }
    )
  return subst
end

-- WARNING: This is not a suitable replacement for urlencode
local escape_string
do
  local escape_subst = create_escape_subst("%%%02X")
  escape_string = function(str)
    return (str:gsub("[%c%z\128-\255]", escape_subst))
  end
end

local url_encode
do
  local escape_subst = create_escape_subst("%%%02X")
  url_encode = function(str)
    return str:gsub("([^%w-_ ])", escape_subst):gsub(" ", "+")
  end
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
    if type(value) == "number" then
      return value
    end
    value = tostring(value)
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

--- Split a string by char.
--
-- Returns an array of strings, each of which is a substring of string formed by
-- splitting it on boundaries formed by the char delimiter.
--
-- @tparam string str Input string
-- @tparam string delimiter Boundary char
-- @treturn table Returns an array of strings created by splitting the string
--   parameter on boundaries formed by the delimiter
local split_by_char = function(str, delimiter)
  assert(type(str) == "string", "Param str must be a string")
  assert(
      type(delimiter) == "string" and #delimiter == 1,
      "Invalid delimiter"
    )

  if str == "" then
    return { }
  end
  
  local sep = delimiter:byte()
  local result = { }
  local pos = 1

  -- lookup delimiter in string
  for i = 1, #str do
    -- delimiter found?
    if str:byte(i) == sep then
      -- store chunk before delimiter
      result[#result + 1] = str:sub(pos, i - 1)
      pos = i + 1
    end
  end
  -- store string remainder
  result[#result + 1] = str:sub(pos)

  return result
end

--- Count the number of substring occurrences.
-- @tparam string str The string to search in
-- @tparam string substr The substring to search for, must be not empty
-- @treturn number Returns the number of substring occurrences
local count_substrings = function(str, substr)
  -- Check substring length to prevent infinite loop
  assert(#substr > 0, "substring must be not empty")

  -- Main calculation loop
  local count = 0
  local s, e = nil, 0
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

--- Split a string into two parts at offset.
-- @tparam string str Input string
-- @tparam number offset Offset at which string will be splitted
-- @treturn table Returns two strings, the first one - is to the left from offset
--   and the second one to the right from offset
local split_by_offset = function(str, offset, skip_right)
  assert(offset <= #str, "offset greater than str length")
  return str:sub(1, offset), str:sub(offset + 1 + (skip_right or 0))
end

--- Expands variables in input string matched by capture string with values
-- from dictionary.
-- @tparam string capture Variable matching expression
-- @tparam string str Input string, containing variables to expand
-- @tparam table dict Dictionary, containing variables's values
-- @treturn string A result string, where variables substituted with values
-- @usage Universal value substitution to any placeholder, for example:
--   fill_placeholders_ex("%$%((.-)%)", "a = $(a)", { a = 42 })
--   returns "a = 42"
-- @see fill_placeholders
-- @see fill_curly_placeholders
local fill_placeholders_ex = function(capture, str, dict)
  return (str:gsub(capture, dict))
end

--- Expands variables like $(varname) with values from dictionary.
-- @tparam string str Input string, containing variables to expand
-- @tparam table dict Dictionary, containing variables's values
-- @treturn string A result string, where variables substituted with values
-- @usage fill_placeholders("a = $(a)", { a = 42 })
--   returns "a = 42"
local fill_placeholders = function(str, dict)
  return fill_placeholders_ex("%$%((.-)%)", str, dict)
end

--- Expands variables like ${varname} with values from dictionary.
-- @tparam string str Input string, containing variables to expand
-- @tparam table dict Dictionary, containing variables's values
-- @treturn string A result string, where variables substituted with values
-- @usage fill_placeholders("a = ${a}", { a = 42 })
--   returns "a = 42"
local fill_curly_placeholders = function(str, dict)
  return fill_placeholders_ex("%${(.-)}", str, dict)
end

--- Convert non-hierarchical table into string.
--
-- Values of key and value are concatted using custom glue `kv_glue`.
-- Allowed values for key and value are numbers and strings.
-- Pairs are concatted using custom glue `pair_glue`.
-- Table can be traversed using custom iterator `pairs_fn`.
-- @tparam table t Non-hierarchical table with [key]=value pairs
-- @tparam string kv_glue Glue between key and value
-- @tparam string pair_glue Glue between pairs (defaut: "")
-- @tparam function pairs_fn Table iterator (default: pairs)
-- @treturn string A result string
-- @usage kv_concat({a = 1, b = 2}, " => ", "; ", pairs)
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
    ["\0"] = "%z";
  }

  escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
  end
end

local escape_for_json
do
  -- Based on luajson code (comments copied verbatim).
  -- https://github.com/harningt/luajson/blob/master/lua/json/encode/strings.lua

  local matches =
  {
    ['"'] = '\\"';
    ['\\'] = '\\\\';
--    ['/'] = '\\/'; -- TODO: ?! Do we really need to escape this?
    ['\b'] = '\\b';
    ['\f'] = '\\f';
    ['\n'] = '\\n';
    ['\r'] = '\\r';
    ['\t'] = '\\t';
    ['\v'] = '\\v'; -- not in official spec, on report, removing
  }

  -- Pre-encode the control characters to speed up encoding...
  -- NOTE: UTF-8 may not work out right w/ JavaScript
  -- JavaScript uses 2 bytes after a \u... yet UTF-8 is a
  -- byte-stream encoding, not pairs of bytes (it does encode
  -- some letters > 1 byte, but base case is 1)
  for i = 0, 255 do
    local c = string.char(i)
    if c:match('[%z\1-\031\128-\255]') and not matches[c] then
      -- WARN: UTF8 specializes values >= 0x80 as parts of sequences...
      --       without \x encoding, do not allow encoding > 7F
      matches[c] = ('\\u%.4X'):format(i)
    end
  end

  escape_for_json = function(s)
    return '"' .. s:gsub('[\\"/%z\1-\031]', matches) .. '"'
  end
end

local starts_with = function(str, prefix)
  if type(str) ~= 'string' or type(prefix) ~= 'string' then return false end
  local plen = #prefix
  return (#str >= plen) and (str:sub(1, plen) == prefix)
end

local ends_with = function(str, suffix)
  if type(str) ~= 'string' or type(suffix) ~= 'string' then return false end
  local slen = #suffix
  return slen == 0 or ((#str >= slen) and (str:sub(-slen, -1) == suffix))
end

local integer_to_string_with_base
do
  -- TODO: use arbitrary set of digits
  -- https://github.com/lua-nucleo/lua-nucleo/issues/2
  local digits =
  {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B";
    "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N";
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z";
  }

  integer_to_string_with_base = function(n, base)
    base = base or 10

    assert(type(n) == "number", "n must be a number")
    assert(type(base) == "number", "base must be a number")
    assert(base > 0 and base <= #digits, "base out of range")

    assert(n == n, "n is nan")
    assert(n ~= 1 / 0 and n ~= -1 / 0, "n is inf")

    n = math_floor(n)
    if base == 10 or n == 0 then
      return tostring(n)
    end

    local sign = ""
    if n < 0 then
      sign = "-"
      n = -n
    end

    local r = { }
    while n ~= 0 do
      r[#r + 1] = digits[(n % base) + 1]
      n = math_floor(n / base)
    end
    return sign .. table_concat(r, ""):reverse()
  end
end

local cut_with_ellipsis
do
  local ellipsis = "..."
  local ellipsis_length = #ellipsis

  cut_with_ellipsis = function(str, max_length)

    max_length = max_length or 80
    arguments(
        "string", str,
        "number", max_length
      )

    assert(max_length > 0, "required string length must be positive")

    if #str > max_length then
      if max_length > ellipsis_length then
        str = str:sub(1, max_length - ellipsis_length) .. ellipsis
      else
        str = str:sub(1, max_length)
      end
   end

    return str
  end
end

-- convert numbers into loadable string, including inf, -inf and nan
local number_to_string
local serialize_number
do
  local t =
  {
    [tostring(1/0)] = "1/0";
    [tostring(-1/0)] = "-1/0";
    [tostring(0/0)] = "0/0";
  }
  number_to_string = function(number)
    -- no argument checking - called very often
    local text = tostring(number)
    return t[text] or text
  end
  serialize_number = function(number)
    -- no argument checking - called very often
    local text = ("%.17g"):format(number)
    -- on the same platform tostring() and string.format()
    -- return the same results for 1/0, -1/0, 0/0
    -- so we don't need separate substitution table
    return t[text] or text
  end
end

local get_escaped_chars_in_ranges
do
  --- Returns '%'-separated character string.
  -- @param ranges If range[i], range[i+1] are numbers, concats all chars ('%'
  -- separated) from char with ranges[1] code to char with ranges[2] code,
  -- concats it to same way to ranges[3] - ranges[4], and so on.
  --
  -- If range[i], range[i+1] are strings,
  -- ignore all string chars but first, and
  -- concats all chars ('%' separated) from ranges[1][1] to ranges[2][1],
  -- concats it to ranges[3][1] - ranges[4][1], and so on.
  --
  -- If range[i], range[i+1] are different types, also works fine, for example:
  -- get_escaped_chars_in_ranges({"0",50}) returns "%0%1%2".
  -- @treturn string Returns '%'-separated character string.
  -- @local here
  get_escaped_chars_in_ranges = function(ranges)
    assert(
        type(ranges) == "table",
        "argument must be a table"
      )

    assert(
        #ranges % 2 == 0,
        "argument must have even number of elements"
      )

    local cat, concat = make_concatter()

    for i = 1, #ranges, 2 do
      local char_code_start = ranges[i]
      local char_code_end = ranges[i + 1]

      if type(char_code_start) == "string" then
        char_code_start = string_byte(char_code_start)
      end
      if type(char_code_end) == "string" then
        char_code_end = string_byte(char_code_end)
      end

      assert(
          type(char_code_start) == "number"
            and type(char_code_end) == "number",
          "argument elements must be numbers or strings"
        )

      for i = char_code_start, char_code_end do
        cat "%" (string_char(i))
      end
    end

    return concat()
  end
end

local tjson_simple
do
  local cat_value = function(cat, v, v_type)
    if v_type == "string" then
      cat (escape_for_json(v))
    elseif v_type == "number" then
      -- Throw exceptions on NaN, +Inf, -Inf
      if v ~= v then
        error("tjson_simple: `NaN' value not supported")
      elseif v == math_huge or v == -math_huge then
        error("tjson_simple: `Inf' value not supported")
      end
      cat (v)
    elseif v_type == "boolean" then
      cat (tostring(v))
    else
      error("tjson_simple: value type `" .. v_type .. "' not supported")
    end
  end

  local function impl(cat, t, visited)
    local t_type = type(t)
    if t_type ~= "table" then
      cat_value(cat, t, t_type)
      return
    end

    if visited[t] then
      error("tjson_simple: can't handle self-references")
    end
    visited[t] = true

    if tisarray(t) then
      cat '['
      if #t > 0 then -- Suppress joining for empty array
        impl(cat, t[1], visited)
        for i = 2, #t do -- Implicit conversion to zero-based array.
          cat ','
          impl(cat, t[i], visited)
        end
      end
      cat ']'
    else
      cat '{'
      local need_comma = false
      for k, v in pairs(t) do
        local k_type = type(k)
        if k_type ~= "string" then
          error("tjson_simple: non-string keys are not supported")
        end
        if need_comma then
          cat ','
        end
        cat_value(cat, k, k_type)
        cat ':'
        impl(cat, v, visited)
        need_comma = true
      end
      cat '}'
    end

    visited[t] = nil
  end

  --- Serialize table into json string.
  --
  -- Tables with string keys only becomes objects. Tables with integer keys
  -- without gaps becomes arrays. Value types nil, NaN, +Inf, -Inf is not
  -- supported.
  -- @tparam table t Table without self-references
  -- @treturn string A result string
  -- @usage tjson_simple({a = 1, b = 2})
  --   returns '{"a":1,"b":2}'
  -- @local here
  tjson_simple = function(t)
    local cat, concat = make_concatter()
    impl(cat, t, { })
    return concat()
  end
end

--- Try to convert input variable into number.
--
-- In case of convertation was unsuccessful returns original variable.
-- @tparam variable v Various type variable
-- @treturn Number or original variable
-- @usage maybe_tonumber("1")
--   returns 1
local maybe_tonumber = function(v)
  return tonumber(v) or v
end

-- TODO: Optimize?
--- Expands variables like ${varname} with values from dictionary.
--
-- If string key 'varname' missing in dictionary, then function trying
-- convert string key to number and found dictionary value with number key.
-- @tparam string str Input string, containing variables to expand
-- @tparam table dict Dictionary, containing variables's values
-- @treturn string A result string, where variables substituted with values
-- @usage fill_placeholders("a = ${1}", { [1] = 42 })
--   returns "a = 42"
-- @see fill_curly_placeholders
local fill_curly_placeholders_numkeys = function(str, dict)
  return fill_curly_placeholders(
    str,
    setmetatable({ }, {
      __index = function(_, k)
        return dict[k] or dict[tonumber(k)]
      end;
    })
  )
end

-- TODO: write test & documentation
local fill_code_placeholders
do
  local cache = setmetatable({ }, {
    __metatable = 'lua-nucleo.string.fill_code_placeholders.cache';
    __mode = 'k';
    __index = function(t, k)
      local v = assert(load('return ' .. k, k))
      t[k] = v
      return v
    end;
  })

  fill_code_placeholders = function(template, env)
    return fill_placeholders_ex('%$<(.-)>', template, function(code)
      return setfenv(cache[code], env)()
    end)
  end
end

--- Parse string with dice notation.
--
-- @tparam string str Input string, containing dice notation
-- @treturn table Dictionary, containing roll parameters
-- @usage parse_dice_notation("1d6+2")
--   returns { a = 1, x = 6, b = 2 }
local parse_dice_notation = function(str)
  local a, x, b = str:match('^(%d-)d(%d+)([+-]-%d-)$')
  if x == '' or x == nil or b == '+' or b == '-' then
    error('bad dice notation `' .. str .. '`', 2)
  end
  if a == '' then
    a = 1
  end
  if b == '' then
    b = nil
  end

  return { a = tonumber(a), x = tonumber(x), b = tonumber(b) }
end

--- Escape string for CSV
--
-- Enclose string containing line breaks (CRLF), and commas in double-quotes.
-- Additionally escape a double-quote appeared inside string with another
-- preceding double-quote.
-- @tparam string str Input string for escaping
-- @treturn string Escaped string
-- @usage escape_for_csv('"a"')
--   returns '""a""'
local escape_for_csv = function(str)
  if str == nil then
    return ''
  end

  str = tostring(str):gsub('"', '""')

  if not str:find('[,\n]') then
    return str
  end

  return '"' .. str .. '"'
end

--- Generate RFC-4180 CSV from table
--
-- Generate CSV from key-value {{ x = "a", y = "b" }, { x = "c", y = "d" }}
-- or keyless {{ "a", "b" }, { "c", "d" }} table with optional custom columns
-- and line delimiters. If table contains keyless values numeric ascending
-- column headers will be generated. Additionally columns in generated CVS
-- can be filtered and/or ordered by optional keys table.
-- @tparam table t Table with keys values pairs or just values
-- @tparam[opt={}] table keys Table with header keys for generated CSV
-- @tparam[opt=false] boolean skip_headers Omit headers in generated CSV
--                    if true
-- @tparam[opt=","] string delimiter String for columns delimitation
-- @tparam[opt="\r\n"] string newline String for lines division
-- @treturn string A result string, contain generated CSV
-- @usage
-- ticsv_simple({{ x = "a", y = "b" }, { x = "c", y = "d" }})
--   returns 'x,y
--            a,b
--            c,d'
-- ticsv_simple(
--   {{ "a", "b", "c" }, { "d", "e", "f" }},
--   { 1, 2 },
--   true,
--   ";",
--   "|"
-- )
--   returns 'a;b|d;e|'
local ticsv_simple = function(t, keys, skip_headers, delimiter, newline)
  if #t == 0 then
    return ''
  end

  delimiter = delimiter or ','
  newline = newline or '\r\n'

  if not keys then
    keys = tkeys(t[1])
    table.sort(keys) -- For convenience.
  end

  local cat, concat = make_concatter()

  if not skip_headers then
    cat (escape_for_csv(keys[1]))
    for i = 2, #keys do
      cat (delimiter) (escape_for_csv(keys[i]))
    end

    cat (newline)
  end

  for i = 1, #t do
    cat (escape_for_csv(t[i][keys[1]]))

    for j = 2, #keys do
      cat (delimiter) (escape_for_csv(t[i][keys[j]]))
    end

    cat (newline)
  end

  return concat()
end

return
{
  escape_string = escape_string;
  make_concatter = make_concatter;
  trim = trim;
  create_escape_subst = create_escape_subst;
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
  escape_for_json = escape_for_json;
  starts_with = starts_with;
  ends_with = ends_with;
  url_encode = url_encode;
  integer_to_string_with_base = integer_to_string_with_base;
  cut_with_ellipsis = cut_with_ellipsis;
  number_to_string = number_to_string;
  serialize_number = serialize_number;
  get_escaped_chars_in_ranges = get_escaped_chars_in_ranges;
  tjson_simple = tjson_simple;
  maybe_tonumber = maybe_tonumber;
  fill_curly_placeholders_numkeys = fill_curly_placeholders_numkeys;
  fill_code_placeholders = fill_code_placeholders;
  parse_dice_notation = parse_dice_notation;
  escape_for_csv = escape_for_csv;
  ticsv_simple = ticsv_simple;
}
