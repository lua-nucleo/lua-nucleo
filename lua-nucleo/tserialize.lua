-- tserialize.lua: Serialize arbitrary Lua data to Lua code
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- Serializes arbitrary lua tables to lua code
-- that can be loaded back via loadstring()
-- Functions, threads, userdata are not supported
-- Metatables are ignored
-- Usage:
--     str = tserialize(explist) --> to serialize data
--     =(loadstring(str)()) --> to load it back


local tserialize
do
  local pairs, type, ipairs, tostring = pairs, type, ipairs, tostring
  local table_concat, table_remove = table.concat, table.remove
  local string_format, string_match = string.format, string.match

  assert(type(import)=="function", "tserialize: import is required to run")

  local lua51_keywords = import 'lua-nucleo/language.lua' { 'lua51_keywords' }

  local cat = function(v, cur_buf)
    cur_buf[#cur_buf + 1] = v
  end

  local function explode_rec(t, add, vis, added)
    local t_type = type(t)
    if t_type == "table" then
      if not (added[t] or vis[t]) then
        vis[t] = true
        for k,v in pairs(t) do
          explode_rec(k, add, vis, added)
          explode_rec(v, add, vis, added)
        end
      else
        if not added[t] and vis[t] then
          added[t] = true
          add[#add+1] = t
        end
      end
    end
  end

  local parse_rec
  do
    local started

    local function impl(t, added, rec_info)
      local t_type = type(t)
      local rec = false
      if t_type == "table" then
        if not added[t]or not started then
          started = true
          for k, v in pairs(t) do
            if impl(k, added, rec_info) or impl(v, added, rec_info) then
              rec = true
              if type(k) == "table" then
                rec_info[k] = true
              end
              if type(v) == "table" then
                rec_info[v] = true
              end
            end
          end
        else
          return true
        end
      end
      return rec
    end

    parse_rec = function(t, added, rec_info)
      started = false
      rec_info[t] = true
      impl(t, added, rec_info)
    end

  end

--  local after -- where to put afterwork info. This var is reused.
  local function recursive_proceed(t, added, rec_info, after, buf)
    local t_type = type(t)
    if t_type == "table" then
      if not added[t] then
        cat("{", buf)
        -- Serialize numeric indices
        local next_i = 0
        for i, v in ipairs(t) do
          next_i = i
          if not (rec_info[i] or rec_info[v]) then
            if i ~= 1 then cat(",", buf) end
            recursive_proceed(v, added, rec_info, after, buf)
          else
            next_i = i - 1
            break
          end
        end
        next_i = next_i + 1
        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local comma = (next_i > 1) and "," or ""
        for k, v in pairs(t) do
          local k_type = type(k)
          if not (rec_info[k] or rec_info[v]) then
          --that means, if the value does not contain a recursive link
          -- to the table itself
          --and the index does not contain a recursive link...
            if k_type == "string"  then
              cat(comma, buf)
              comma = ","
              --check if we can use the short notation
              -- eg {a=3,b=5} istead of {["a"]=3,["b"]=5}
              if
                not lua51_keywords[k] and string_match(k, "^[%a_][%a%d_]*$")
              then
                cat(k, buf); cat("=", buf)
              else
                cat(string_format("[%q]=", k), buf)
              end
                recursive_proceed(v, added, rec_info, after, buf)
            elseif
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integral key.
            then
              cat(comma, buf)
              comma = ","
              cat("[", buf)
              recursive_proceed(k, added, rec_info, after, buf)
              cat("]", buf)
              cat("=", buf)
              recursive_proceed(v, added, rec_info, after, buf)
            end
          else
            after[#after + 1] = {k,v}
          end
        end
        cat("}", buf)
      else -- already visited!
        cat(added[t].name, buf)
      end
    elseif t_type == "string" then
      cat(string_format("%q", t), buf)
    elseif t_type == "number" then
      cat(string_format("%.55g",t), buf)
    elseif t_type == "boolean" then
      cat(tostring(t), buf)
    elseif t == nil then
      cat("nil", buf)
    else
      return nil
    end
    return true
  end

  local afterwork = function(k, v, buf, name, added, rec_info)
    cat(" ", buf)
    cat(name, buf)
    cat("[", buf)
    local after = buf.afterwork
    if not recursive_proceed(k, added, rec_info, after, buf) then
      return false
    end
    cat("]=", buf)
    if not recursive_proceed(v, added, rec_info, after, buf) then
      return false
    end
    cat(" ", buf)
    return true
  end

  tserialize = function (...)
  --===================================--
  --===========THE MAIN PART===========--
  --===================================--
    --PREPARATORY WORK: LOCATE THE RECURSIVE AND SHARED PARTS--
    local narg = select("#", ...)
    local visited = {}
    -- table, containing recursive parts of our variables
    local additional_vars = { }
    local add_hash = {}
    for i = 1, narg do
      local v = select(i, ...)
      explode_rec(v, additional_vars, visited, add_hash) -- discover recursive subtables
    end
    visited = nil -- no more needed
    local nadd = #additional_vars
    --SERIALIZE ADDITIONAL FIRST--
    local rec_info = {}

    for i = 1, nadd do
      local v = additional_vars[i]
      parse_rec(v, add_hash, rec_info)
    end
    add_hash = nil -- no more needed
    local added = {}
    local buf = {}
    for i = 1, nadd do
      local v = additional_vars[i]
      buf[i] = {afterwork = {}}
      local after = buf[i].afterwork
      if not recursive_proceed(v, added, rec_info, after, buf[i]) then
        return nil, "Unserializable data in parameter #" .. i
      end
      added[v] = {name = "var" .. i, num = i}
    end

    rec_info = {}
    for i = 1, nadd do
      local v = additional_vars[i]
      buf[i].afterstart = #buf[i]
      for j = 1, #(buf[i].afterwork) do
        if not afterwork(
              buf[i].afterwork[j][1],
              buf[i].afterwork[j][2],
              buf[i],
              added[v].name,
	      added,
	      rec_info
            )
        then
          return nil, "Unserializable data in parameter #" .. i
        end
      end
    end

    --SERIALIZE GIVEN VARS--

    for i = 1, narg do
      local v = select(i, ...)
      buf[i + nadd] = {afterwork = {}}
      local after = buf[i + nadd].afterwork
      if not recursive_proceed(v, added, rec_info, after, buf[i + nadd]) then
        return nil, "Unserializable data in parameter #" .. i
      end
    end

    --DECLARE ADDITIONAL VARS--

    local prevbuf = {}
    for v, inf in pairs(added) do
      prevbuf[ #prevbuf + 1] =
           " local " .. inf.name
        .. "=" .. table_concat(buf[inf.num], "", 1, buf[inf.num].afterstart)
    end

    --CONCAT PARTS--
    for i = 1, nadd do
      buf[i] = table_concat(buf[i], "", buf[i].afterstart + 1)
    end
    for i = nadd + 1, nadd+narg do
      buf[i] = table_concat(buf[i])
    end

    --RETURN THE RESULT--

    if  nadd == 0 then
      return "return " .. table_concat(buf,",")
    else
      local rez = {
        "do ";
        table_concat(prevbuf, " ");
        ' ';
        table_concat(buf, " ", 1, nadd);
        " return ";
        table_concat(buf, ",", nadd+1);
        " end";
      }
      return table_concat(rez)
    end
  end
end

return
{
  tserialize = tserialize;
}
