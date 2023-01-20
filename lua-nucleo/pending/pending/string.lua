-- luacheck: globals import

require 'lua-nucleo'

local tkeys = import 'lua-nucleo/table-utils.lua' { 'tkeys' }

local fill_curly_placeholders,
      fill_placeholders_ex,
      make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'fill_curly_placeholders',
        'fill_placeholders_ex',
        'make_concatter'
      }

local setfenv = import 'lua-nucleo/pending/compatibility.lua' { 'setfenv' }

local maybe_tonumber = function(v)
  return tonumber(v) or v
end

-- TODO: Optimize?
local fill_curly_placeholders_numkeys = function(template, dict)
  return fill_curly_placeholders(
    template,
    setmetatable({ }, {
      __index = function(_, k)
        return dict[k] or dict[tonumber(k)]
      end;
    })
  )
end

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

local parse_dice_notation = function(s)
  local a, x, b = s:match('^(%d-)d(%d+)([+-]-%d-)$')
  if x == '' or x == nil or b == '+' or b == '-' then
    error('bad dice notation `' .. s .. '`', 2)
  end
  if a == '' then
    a = 1
  end
  if b == '' then
    b = nil
  end

  return { a = tonumber(a), x = tonumber(x), b = tonumber(b) }
end

local escape_for_csv = function(s)
  if s == nil then
    return ''
  end

  s = tostring(s):gsub('"', '""')

  if not s:find('[,\n]') then
    return s
  end

  return '"' .. s .. '"'
end

-- Attempts to write RFC-4180 CSV
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
  maybe_tonumber = maybe_tonumber;
  fill_curly_placeholders_numkeys = fill_curly_placeholders_numkeys;
  fill_code_placeholders = fill_code_placeholders;
  parse_dice_notation = parse_dice_notation;
  escape_for_csv = escape_for_csv;
  ticsv_simple = ticsv_simple;
}
