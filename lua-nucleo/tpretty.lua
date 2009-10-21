-- tstr.lua -- visualization of non-recursive tables.
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local table_concat = table.concat
local string_match, string_format = string.match, string.format

local countlen = function(buf, start, finish)
  local count = 0
  for i = start, finish do
    count = count + string.len(buf[i])
  end
  return count
end


local lua51_keywords = import 'lua-nucleo/language.lua' { 'lua51_keywords' }

local subst =
{
  {", ", "", "", " = "};--linear mode separators
  {";\n", "\n", ";\n", " =\n"};--multiline mode separators
}

local create_prettifier = function(indent, buffer, cols)
  local p = {}
  local ind = indent
  local level = 0
  local septable = {}
  local prev_table_pos = -1
  local prev_table_len = 0

  function p:increase_indent()
    level = level + 1
  end

  function p:decrease_indent()
    level = level - 1
  end

  function p:separator()
    local pos = #buffer + 1
    buffer[pos] = subst[1][1]
    septable[#septable + 1] = {pos, level, 1}
  end

  function p:optional_nl()
    local pos = #buffer + 1
    buffer[pos] = subst[1][2]
    septable[#septable + 1] = {pos, level, 2}
  end

  function p:terminating_sep()
    local pos = #buffer + 1
    buffer[pos] = subst[1][3]
    septable[#septable + 1] = {pos, level, 3}
  end

  function p:table_start()
    self:increase_indent()
    local pos = #buffer + 1
    buffer[pos] = "{"
    septable[#septable + 1] = {pos, level, 5}
    if prev_table_pos > 0 then
      septable[prev_table_pos][3] = 6
    end
    prev_table_pos = #septable
    self:optional_nl()
  end

  function p:table_finish()
    self:decrease_indent()
    self:terminating_sep()
    local pos = #buffer + 1
    buffer[pos] = "}"
    if prev_table_pos > 0 and septable[prev_table_pos][3] == 5 then
      local len = countlen(buffer,septable[prev_table_pos][1],pos)
      prev_table_len = len + level*string.len(indent)
      if prev_table_len > cols then
	septable[prev_table_pos][3] = 6
	prev_table_len = 0
      end
    else
      prev_table_len = 0
    end
    septable[#septable + 1] = {pos, level, 7}
    prev_table_pos = -1
  end

  function p:key_start()
    prev_table_len = 0
  end

  function p:value_start()
    local pos = #buffer + 1
    buffer[pos] = " = "
    if prev_table_len + 5 > cols then
      self:optional_nl()
    end
  end

  function p:key_value_finish()
  end

  function p:finished()
    local mode = 1
    local t = septable;
    for i = 1, #t do
      local pos, level, stype = t[i][1], t[i][2], t[i][3]
      if stype == 5 then
	mode = 1
      elseif stype == 6 then
	mode = 2
      elseif stype == 7 then
	mode = 2
      end
      if stype < 5 and mode ~= 1 then
	buffer[pos] = subst[mode][stype]..string.rep(indent, level)
      end
    end
  end

  return p
end

local tpretty
do
  local add=""
  local function impl(t, cat, prettifier, visited)
    local t_type = type(t)
    if t_type == "table" then
      if not visited[t] then
        visited[t] = true

	prettifier:table_start()

        -- Serialize numeric indices

        for i, v in ipairs(t) do
          if i > 1 then -- TODO: Move condition out of the loop
	    prettifier:separator()
          end
          impl(v, cat, prettifier, visited)
        end

        local next_i = #t + 1

        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local need_comma = (next_i > 1)
        for k, v in pairs(t) do
          local k_type = type(k)
          if k_type == "string" then
	    if need_comma then
	      prettifier:separator()
	    end
	    need_comma = true
	    prettifier:key_start()
            -- TODO: Need "%q" analogue, which would put quotes
            --       only if string does not match regexp below
            if not lua51_keywords[k] and string_match(k, "^[%a_][%a%d_]*$") then
              cat(k)
            else
              cat(string_format("[%q]", k))
            end
	    prettifier:value_start()
            impl(v, cat, prettifier, visited)
	    prettifier:key_value_finish()
          else
            if
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
	      if need_comma then
		prettifier:separator()
	      end
	      need_comma = true
	      prettifier:key_start()
              cat("[")
              impl(k, cat, prettifier, visited)
              cat("]")
	      prettifier:value_start()
              impl(v, cat, prettifier, visited)
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
    elseif t_type == "number" or t_type == "boolean" then
      cat(tostring(t))
    elseif t == nil then
      cat("nil")
    else
      -- Note this converts non-serializable types to strings
      cat(string_format("%q", tostring(t)))
    end
  end

  tpretty = function(t, indent, cols)
    local buf = {}
    local sptable = {};
    local cat = function(v) buf[#buf + 1] = v end
    local pr = create_prettifier(indent, buf, cols)
    impl(t, cat, pr, {})
    pr:finished()
    return table_concat(buf)
  end
end

return
{
  tpretty = tpretty;
}