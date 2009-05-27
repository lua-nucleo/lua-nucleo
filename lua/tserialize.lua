-- tserialize.lua: Serialize arbitrary Lua data to Lua code
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local tserialize=nil
do
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
  local pairs, type, ipairs, tostring = pairs, type, ipairs, tostring
  local table_concat = table.concat
  local string_format, string_match = string.format,string.match

  local function explode_rec(t,add,visited,added,vis)
    local t_type = type(t)
    if t_type == "table" then
      if not (visited[t] or added[t] or vis[t]) then
        visited[t]=true
        vis[t]=true
        for k,v in pairs(t) do
          explode_rec(k,add,visited,added,vis)
          explode_rec(v,add,visited,added,vis)
        end
        vis[t]=nil
      else
        if not added[t] and vis[t] then
          added[t]=true
          add[#add+1]=t
        end
      end
    end
  end

  local function parse_rec(t,visited,rec_info)
    local initial = t
    local function parse_rec_internal(t)
      local t_type = type(t)
      local rec=false
      if t_type == "table" then
        if not visited[t] then
          visited[t]=true
          for k,v in pairs(t) do
            if parse_rec_internal(k) then
              rec=true
              if t==initial then
                rec_info[k]=true
              end
            end
            if parse_rec_internal(v) then
              rec=true
            end
          end
        else
          if t==initial then
            return true
          end
        end
      end
      return rec
    end
    parse_rec_internal(initial)
  end
  local function recursive_proceed(t,buf,visited,num,rec_info,initial, afterwork,declare,cat)
    local t_type = type(t)
    if t_type == "table" then
      if not visited[t] then
        visited[t] = {var_num = num,buf_start=#buf+1,name="var"..visited.n, rec_links={}}
        visited.n = visited.n+1
        cat("{")
        -- Serialize numeric indices
        local next_i=#t+1
        for i=1,next_i-1 do
          local v=t[i]
          if v~=initial then
            if i~=1 then cat(",") end
            recursive_proceed(v,buf,visited,num,rec_info,initial, afterwork,declare,cat)
          end
        end
        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local comma = (next_i > 1) and "," or ""
        for k, v in pairs(t) do
          local k_type = type(k)
          if not (rec_info[k] or v==initial) then
          --that means, if the value is not a recursive link to the table itself
          --and the index does not CONTAIN a recursive link...
            if k_type == "string" then
              cat(comma)
              comma = ","
              --check if we can use the short notation eg {a=3,b=5} istead of {["a"]=3,["b"]=5}
              if not lua51_keywords[k] and string_match(k, "^[%a_][%a%d_]*$") then
                cat(k); cat("=")
              else
                cat(string_format("[%q]", k)) cat("=")
              end
                recursive_proceed(v,buf,visited,num,rec_info,initial, afterwork,declare,cat)
            elseif
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integral key.
            then
              cat(comma)
              comma=","
              cat("[")
              recursive_proceed(k,buf,visited,num,rec_info,initial, afterwork,declare,cat)
              cat("]")
              cat("=")
              recursive_proceed(v,buf,visited,num,rec_info,initial, afterwork,declare,cat)
            end
          else
            afterwork[#afterwork+1]={k,v}
          end
        end
        cat("}")
        visited[t].buf_end=#buf
      else -- already visited!
        cat(visited[t].name)
        if not visited[t].declared then
          declare[#declare+1]=visited[t]
          visited[t].declared=true
        end
      end
    elseif t_type == "string" then
      cat(string_format("%q", t))
    elseif t_type == "number" or t_type == "boolean" then
      cat(tostring(t))
    elseif t == nil then
      cat("nil")
    else
      return nil
    end
    return true
  end

  local function afterwork(k,v,buf,name,visited,rec_buf)
    local cat = function(v) buf[#buf + 1] = v end
    cat(" ")
    cat(name)
    cat("[")
    recursive_proceed(k,buf,visited,num,rec_buf,k, buf.afterwork,visited.declare,cat)
    cat("]=")
    recursive_proceed(v,buf,visited,num,rec_buf,v, buf.afterwork,visited.declare,cat)
    cat(" ")
  end
  tserialize = function (...)
  --===================================--
  --===========THE MAIN PART===========--
  --===================================--
    --PREPARATORY WORK: LOCATE THE RECURSIVE PARTS--
    local narg=#arg
    local additional_vars={} -- table, containing recursive parts of our variables
    local added={}
    local visit={}
    for i,v in pairs(arg) do
      local v=arg[i]
      explode_rec(v, additional_vars,visit,added,{}) -- discover recursive subtables
    end
    added=nil  --need no more
    visit=nil--need no more

    local visited={n=0,declare={}}
    local nadd=#additional_vars
    local visit={}
    --SERIALIZE RECURSIVE FIRST--
    local rec_info={}
    local buf={}
    if nadd~=0 then visited.has_recursion=true end
    for i=1,nadd do
      local v=additional_vars[i]
      parse_rec(v, visit, rec_info)
      buf[i]={afterwork={}}
      if not recursive_proceed(v, buf[i],visited,i,rec_info,v, buf[i].afterwork,visited.declare,function(v) buf[i][#buf[i] + 1] = v end) then
        return nil, "Unserializable data in parameter #"..i
      end
      visited[v].is_recursive=true
    end
    visit=nil --no more needed
    --SERIALIZE GIVEN VARS--

    for i=1,narg do
      local v=arg[i]
      --print(v)
      buf[i+nadd]={afterwork={}}
      if not recursive_proceed(v, buf[i+nadd],visited,i+nadd,rec_info,v, buf[i+nadd].afterwork,visited.declare,function(v) buf[i+nadd][#(buf[i+nadd]) + 1] = v end) then
        return nil, "Unserializable data in parameter #"..i
      end
    end

    --DECLARE THE VARIABLES THAT ARE USED MULTIPLE TIMES --
    local prevbuf={}
    for i,v in ipairs(visited.declare) do
      if not v.is_recursive then --skip recursive fields
        prevbuf[#prevbuf+1] = " local "..v.name.."="..table_concat(buf[v.var_num],"",v.buf_start,v.buf_end)
        buf[v.var_num][v.buf_start]=v.name
        for i=v.buf_start+1,v.buf_end do
          buf[v.var_num][i]=""
        end
      end
    end

    --CONCAT RECURSIVE PART--

    for i=1,nadd do
      local v=additional_vars[i]
      for j=1,#(buf[i].afterwork) do
        afterwork(buf[i].afterwork[j][1],buf[i].afterwork[j][2],buf[i],visited[v].name,visited,rec_info)
      end
      buf[i]=table_concat(buf[i])
      buf[i]="local "..visited[v].name.."="..buf[i]
    end

    --CONCAT MAIN PART

    for i=nadd+1,nadd+narg do
      buf[i]=table_concat(buf[i])
    end

    --RETURN THE RESULT--

    if not visited.has_recursion and #visited.declare==0 then
      return "return "..table_concat(buf,",")
    else
      local rez={
        "do ",
        table_concat(prevbuf,""),
        table_concat(buf,"",1,nadd),
        " return ",
        table_concat(buf,",",nadd+1),
        " end"
      }
      return table_concat(rez)
    end
  end
end
return {tserialize=tserialize}
