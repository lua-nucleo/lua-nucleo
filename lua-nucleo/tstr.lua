--------------------------------------------------------------------------------
--- Visualization of non-recursive tables.
-- @module lua-nucleo.tstr
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local table_concat = table.concat
local string_match, string_format = string.match, string.format

local lua_keywords = import 'lua-nucleo/language.lua' { 'lua_keywords' }
local serialize_number = import 'lua-nucleo/string.lua' { 'serialize_number' }

local tstr, tstr_cat
do
  local function impl(t, cat, visited)
    local t_type = type(t)
    if t_type == "table" then
      if not visited[t] then
        visited[t] = true

        cat("{")

        -- Serialize numeric indices

        local next_i = 0
        while t[next_i + 1] ~= nil and next_i < #t do
          next_i = next_i + 1
          if next_i > 1 then -- TODO: Move condition out of the loop
            cat(",")
          end
          impl(t[next_i], cat, visited)
        end
        next_i = next_i + 1

        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local need_comma = (next_i > 1)
        for k, v in pairs(t) do
          local k_type = type(k)
          if k_type == "string" then
            if need_comma then
              cat(",")
            end
            need_comma = true

            -- TODO: Need "%q" analogue, which would put quotes
            --       only if string does not match regexp below
            if not lua_keywords[k] and string_match(k, "^[%a_][%a%d_]*$") then
              cat(k) cat("=")
            else
              cat(string_format("[%q]=", k))
            end
            impl(v, cat, visited)
          else
            if
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
              if need_comma then
                cat(",")
              end
              need_comma = true

              cat("[")
              impl(k, cat, visited)
              cat("]=")
              impl(v, cat, visited)
            end
          end
        end

        cat("}")

        visited[t] = nil
      else
        -- Note this loses information on recursive tables
        cat('"table (recursive)"')
      end
    elseif t_type == "number" then
      cat(serialize_number(t))
    elseif t_type == "boolean" then
      cat(tostring(t))
    elseif t == nil then
      cat("nil")
    else
      -- Note this converts non-serializable types to strings
      cat(string_format("%q", tostring(t)))
    end
  end

  -- This function is optimized for logging.
  -- Unless you are serializing "simple" tables,
  -- do not use this function for serialization.
  -- This function intentionally loses information on nested recursive tables
  -- and on non-serializable types like functions, threads and userdata.

  tstr_cat = function(cat, t)
    impl(t, cat, {})
  end

  tstr = function(t)
    local buf = {}
    local cat = function(v) buf[#buf + 1] = v end
    impl(t, cat, {})
    return table_concat(buf)
  end
end

return
{
  tstr = tstr;
  tstr_cat = tstr_cat;
}
