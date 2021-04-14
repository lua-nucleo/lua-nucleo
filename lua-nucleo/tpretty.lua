--------------------------------------------------------------------------------
--- Pretty visualization of non-recursive tables.
-- @module lua-nucleo.tpretty
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local table_concat = table.concat
local string_match, string_format = string.match, string.format

local lua_keywords = import 'lua-nucleo/language.lua' { 'lua_keywords' }
local make_prettifier = import 'lua-nucleo/prettifier.lua' { 'make_prettifier' }
local is_table = import 'lua-nucleo/type.lua' { 'is_table' }
local tstr = import 'lua-nucleo/tstr.lua' { 'tstr' }
local arguments = import 'lua-nucleo/args.lua' { 'arguments' }
local number_to_string = import 'lua-nucleo/string.lua' { 'number_to_string' }
local ordered_pairs = import 'lua-nucleo/tdeepequals.lua' { 'ordered_pairs' }

local tpretty_ex, tpretty, tpretty_ordered
do
  local function impl(iterator, t, cat, prettifier, visited)
    local t_type = type(t)
    if t_type == 'table' then
      if not visited[t] then
        visited[t] = true

        prettifier:table_start()

        -- Serialize numeric indices

        local next_i = 0
        for i, v in ipairs(t) do
          if i > 1 then -- TODO: Move condition out of the loop
            prettifier:separator()
          end
          impl(iterator, v, cat, prettifier, visited)
          next_i = i
        end

        next_i = next_i + 1

        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local need_comma = (next_i > 1)
        for k, v in iterator(t) do
          local k_type = type(k)
          if k_type == 'string' then
            if need_comma then
              prettifier:separator()
            end
            need_comma = true
            prettifier:key_start()
            -- TODO: Need "%q" analogue, which would put quotes
            --       only if string does not match regexp below
            if not lua_keywords[k] and string_match(k, '^[%a_][%a%d_]*$') then
              cat(k)
            else
              cat(string_format('[%q]', k))
            end
            prettifier:value_start()
            impl(iterator, v, cat, prettifier, visited)
            prettifier:key_value_finish()
          else
            if
              k_type ~= 'number' or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
              if need_comma then
                prettifier:separator()
              end
              need_comma = true
              prettifier:key_start()
              cat('[')
              impl(iterator, k, cat, prettifier, visited)
              cat(']')
              prettifier:value_start()
              impl(iterator, v, cat, prettifier, visited)
              prettifier:key_value_finish()
            end
          end
        end
        prettifier:table_finish()

        visited[t] = nil
      else
        -- Note this loses information on recursive tables
        cat('"table (recursive)"')
      end
    elseif t_type == 'number' then
      cat(number_to_string(t))
    elseif t_type == 'boolean' then
      cat(tostring(t))
    elseif t == nil then
      cat('nil')
    else
      -- Note this converts non-serializable types to strings
      cat(string_format('%q', tostring(t)))
    end
  end

  tpretty_ex = function(iterator, t, indent, cols)
    indent = indent or '  '
    cols = cols or 80 --standard screen width

    if not is_table(t) then
      return tstr(t)
    end

    arguments(
        -- all arguments should be listed, even though t is checked before
        'function', iterator,
        --"table", t
        'string', indent,
        'number', cols
      )

    local buf = {}
    -- make_prettifier works with external buf, so special formatter cat
    -- is used instead of make_concatter
    local cat = function(v) buf[#buf + 1] = v end
    local pr = make_prettifier(indent, buf, cols)
    impl(iterator, t, cat, pr, {})
    pr:finished()
    return table_concat(buf)
  end

  tpretty = function(t, indent, cols)
    return tpretty_ex(pairs, t, indent, cols)
  end

  tpretty_ordered = function(t, indent, cols)
    return tpretty_ex(ordered_pairs, t, indent, cols)
  end
end

return
{
  tpretty_ex = tpretty_ex;
  tpretty = tpretty;
  tpretty_ordered = tpretty_ordered;
}
