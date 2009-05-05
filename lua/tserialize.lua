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
  local rec_info={}
  local vis={}
  local function explode_rec(t,visited,add)
    local t_type = type(t)
    if t_type == "table" then
      if not visited[t] then
        visited[t]=true
        for k,v in pairs(t) do
          explode_rec(k,visited,add)
          explode_rec(v,visited,add)
        end
        visited[t]=nil
      else
        if not vis[t] then
          visited.has_recursion=true
          vis[t]=true
          add=[#add+1]=t
        end
      end
    end
  end
  local function parse_rec(t,visited,initial)
    local t_type = type(t)
    local rec=false
    if t_type == "table" then
      if not visited[t] then
        visited[t]=true
        for k,v in pairs(t) do
          if parse_rec(k,visited,initial) then rec=true if initial==t then  rec_info[k]=true end end
          if parse_rec(v,visited,initial) then rec=true end
        end
        visited[t]=nil
      else
        if t==initial then
          return true
        end
      end
    end
    return rec
  end
  local function recursive_proceed(t,buf,afterwork,visited,num,initial)
    local t_type = type(t)
    local cat = function(v) buf[#buf + 1] = v end
    if t_type == "table" then
      if not visited[t] then
        visited[t] = {var_num = num,buf_start=#buf+1,name="var"..visited.n, rec_links={}}
        visited.n = visited.n+1
        cat("{")
        -- Serialize numeric indices
        -- using ipairs instead of direct indexing - maybe slower...
        local next_i=1
        for i,v in ipairs(t) do
          if v~=initial then
            if i~=1 then cat(",") end
            recursive_proceed(v,buf,afterwork,visited,num,initial)
          end
          next_i= i + 1
        end
        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local comma = (next_i > 1) and "," or ""
        for k, v in pairs(t) do
          local k_type = type(k)
          if not (rec_info[k] or v==initial) then
            if k_type == "string" then
              cat(comma)
              comma = ","
              --check if we can use the short notation eg {a=3,b=5} istead of {["a"]=3,["b"]=5}
              if not lua51_keywords[k] and string.match(k, "^[%a_][%a%d_]*$") then
                cat(k); cat("=")
              else
                cat(string_format("[%q]", k)) cat("=")
              end
                recursive_proceed(v, buf,afterwork, visited,num,initial)
            elseif
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
              cat(comma)
              comma=","
              cat("[")
              recursive_proceed(k, buf,afterwork, visited,num,initial)
              cat("]")
              cat("=")
              recursive_proceed(v, buf,afterwork, visited,num,initial)
            end
          else
            afterwork[#afterwork+1]={k,v}
          end
        end
        cat("}")
        visited[t].buf_end=#buf
        visited[t].recursive=nil
      else -- already visited!
        cat(visited[t].name)
        visited[t].needs_declaration=true
        visited.need_locals=true
      end
    elseif t_type == "number" or t_type == "boolean" then
      cat(tostring(t))
    elseif t == nil then
      cat("nil")
    else
      return nil
    end
    return true
  end
  local function afterwork(k,v,buf,initial,name,visited)
    local cat = function(v) buf[#buf + 1] = v end
    cat(" ")
    cat(name)
    cat("[")
    recursive_proceed(k,buf,buf.afterwork,visited,num,initial)
    cat("]=")
    recursive_proceed(v,buf,buf.afterwork,visited,num,initial)
    cat(" ")
  end
  tserialize = function (...)
  --===================================--
  --===========THE MAIN PART===========--
  --===================================--

  --PREPARATORY WORK: LOCATE THE RECURSIVE PARTS--

    local additional_vars={} -- table, containing recursive parts of our variables
    
    for i=1,#arg do
      v=arg[i]
      explode_rec(v, {} ,additional_vars) -- discover recursive subtables
    end
    local visited={n=0}
    local nadd=#additional_vars

    --SERIALIZE RECURSIVE FIRST--

    local buf={}
    if nadd~=0 then visited.has_recursion=true end
    for i=1,nadd do
      v=additional_vars[i]
      parse_rec(v, visited,v)
      buf[i]={afterwork={}}
      if not recursive_proceed(v, buf[i], buf[i].afterwork,visited,i,v) then
        return nil, "Unserializable data in parameter #"..i
      end
      visited[v].is_recursive=true
    end

    --SERIALIZE GIVEN VARS--

    for i=1,#arg do
      v=arg[i]
      --print(v)
      buf[i+nadd]={}
      if not recursive_proceed(v, buf[i+nadd],buf[i+nadd].afterwork, visited,i+nadd) then
        return nil, "Unserializable data in parameter #"..i
      end
    end

    --DECLARE THE VARIABLES THAT ARE USED MULTIPLE TIMES --

    local lindex=0
    for _,v in pairs(visited) do
      if type(v)=="table" and v.needs_declaration and not v.is_recursive then --skip nontable fields and "normal" tables
        buf[lindex] = " local "..v.name.."="..table.concat(buf[v.var_num],"",v.buf_start,v.buf_end)
        buf[v.var_num][v.buf_start]=v.name
        for i=v.buf_start+1,v.buf_end do
          buf[v.var_num][i]="" -- TODO Ugly, but works
        end
        lindex = lindex -1
      end
    end

    --CONCAT RECURSIVE PART--

    for i=1,nadd do
      v=additional_vars[i]
      for j=1,#(buf[i].afterwork) do
        afterwork(buf[i].afterwork[j][1],buf[i].afterwork[j][2],buf[i],v,visited[v].name,visited)
      end
      buf[i]=table.concat(buf[i])
      buf[i]="local "..visited[v].name.."="..buf[i]
    end

    --CONCAT MAIN PART

    for i=nadd+1,nadd+#arg do
      buf[i]=table.concat(buf[i])
    end

    --RETURN THE RESULT--

    if not visited.has_recursion and not visited.need_locals then
      return "return "..table.concat(buf,",")
    else
      local rez={
        "do ",
        table.concat(buf,"",lindex+1,0),
        table.concat(buf,"",1,nadd),
        " return ",
        table.concat(buf,",",nadd+1),
        " end"
      }
      return table.concat(rez)
    end
  end
end
--examples
--local t = {}
--t[1] = t

--local t = {{}}
--t[t]=t
--[[t1={1}
t1[{2,t1}]=t1
t1[2]=t1
print(tserialize(t1,{1,3,t1}))--]]
--[[t={{1},{2}}
t[1][2]=t[2]
t[2][2]=t[1]--]]

--[[
t1={}
t1[t1]=t1
t2={2,3,4,5,t1}
t2[t2]=t2
t3={t2,t1}
t3[t3]=t2
print(tserialize(t2,t3))--]]
