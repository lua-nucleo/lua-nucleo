-- tserialize.lua: Serialize arbitrary Lua data to Lua code
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- To load do assert(loadstring("return "..tshow_result))
do
  function tserialize(...)
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
            table.insert(add,t)
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
    local function afterwork_proceed(t,buf,visited,num,initial)
      local t_type = type(t)
      local cat = function(v) buf[#buf + 1] = v end
      if t_type == "table" then
        --print(rec_info[t])
        if not visited[t] then
          visited[t] = {var_num = num,buf_start=#buf+1,name="var"..visited.n, rec_links={}}
          visited.n = visited.n+1
          cat("{")
          -- Serialize numeric indices
          -- using ipairs instead of direct indexing - maybe slower...
          local next_i=1
          for i,v in ipairs(t) do 
            if i~=1 then cat(",") end
            afterwork_proceed(v,buf,visited,num,initial)
            next_i= i + 1
          end
          -- Serialize hash part
          -- Skipping comma only at first element if there is no numeric part.
          local comma = (next_i > 1) and "," or ""
          for k, v in pairs(t) do
            local k_type = type(k)
            if k_type == "string" then
              cat(comma)
              comma = ","
              --check if we can use the shot notation eg {a=3,b=5} istead of {["a"]=3,["b"]=5}
              if not lua51_keywords[k] and string.match(k, "^[%a_][%a%d_]*$") then
                cat(k); cat("=")
              else
                cat(string_format("[%q]", k)) cat("=")
              end
              afterwork_proceed(v, buf, visited,num,initial) 
            elseif
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
              cat(comma)
              comma=","
              cat("[")
              afterwork_proceed(k, buf, visited,num,initial)
              cat("]")
              cat("=")
              afterwork_proceed(v, buf, visited,num,initial)
            end
          end
          cat("}")
          visited[t].buf_end=#buf
          visited[t].recursive=nil
        else -- already visited!
          cat(visited[t].name)
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
      afterwork_proceed(k,buf,visited,num,initial)
      cat("]=")
      afterwork_proceed(v,buf,visited,num,initial)
    end
    
    local function recursive_proceed(t,buf,visited,num,initial)
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
              recursive_proceed(v,buf,visited,num,initial)
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
                  recursive_proceed(v, buf, visited,num,initial) 
              elseif
                k_type ~= "number" or -- non-string non-number
                k >= next_i or k < 1 or -- integer key in hash part of the table
                k % 1 ~= 0 -- non-integer key
              then
                cat(comma)
                comma=","
                cat("[")
                recursive_proceed(k, buf, visited,num,initial)
                cat("]")
                cat("=")
                recursive_proceed(v, buf, visited,num,initial)
              end
            else table.insert(buf.afterwork,{k,v}) end
          end
          cat("}")
          visited[t].buf_end=#buf
          visited[t].recursive=nil
        else -- already visited!
          cat(visited[t].name)
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
    --[[local function proceed(t,buf,visited,num)
      local t_type = type(t)
      local cat = function(v) buf[#buf + 1] = v end
      if t_type == "table" then
        if not visited[t] then
          visited[t] = {var_num = num,buf_start=#buf+1,name="var"..visited.n}
          visited.n = visited.n+1
          cat("{")
          -- Serialize numeric indices
          -- using ipairs instead of direct indexing - maybe slower...
          local next_i=1
          for i,v in ipairs(t) do 
            if i~=1 then cat(",") end
            proceed(v,buf,visited,num)
            next_i= i + 1
          end
          -- Serialize hash part
          -- Skipping comma only at first element if there is no numeric part.
          local comma = (next_i > 1) and "," or ""
          for k, v in pairs(t) do
            local k_type = type(k)
            if k_type == "string" then
              cat(comma)
              comma = ","
              --check if we can use the shot notation eg {a=3,b=5} istead of {["a"]=3,["b"]=5}
              if not lua51_keywords[k] and string.match(k, "^[%a_][%a%d_]*$") then
                cat(k); cat("=")
              else
                cat(string_format("[%q]=", k))
              end
              proceed(v, buf, visited,num) 
            elseif
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
              cat(comma)
              comma=","
              cat("[")
              proceed(k, buf, visited,num)
              cat("]=")
              proceed(v, buf, visited,num)
            end
          end
          cat("}")
          visited[t].buf_end=#buf
        else -- already visited!
          visited.need_locals=not visited[t].is_recursive or visited.need_locals
          visited[t].needs_declaration = not visited[t].is_recursive
          cat(visited[t].name)
        end
      elseif t_type == "number" or t_type == "boolean" then
        cat(tostring(t))
      elseif t == nil then
        cat("nil")
      else
        return nil
      end
      return true
    end--]]
    
    local add={}
    local visited={n=0, need_locals=false}
    for i=1,#arg do
      v=arg[i]
      explode_rec(v, visited,add)
    end
    visited.n=0
    --proceed recursive subtables first...
    local rec_buf={}
    for i=1,#add do
      v=add[i]
      --print("processing recursive subtable:",v)
      parse_rec(v, visited,v)
      rec_buf[i]={afterwork={}}
      if not recursive_proceed(v, rec_buf[i], visited,i,v) then 
        return nil, "Unserializable data in parameter #"..i
      end
      visited[v].is_recursive=true
      --print(table.concat(rec_buf[i]),#(rec_buf[i].afterwork))
      for j=1,#(rec_buf[i].afterwork) do
        afterwork(rec_buf[i].afterwork[j][1],rec_buf[i].afterwork[j][2],rec_buf[i],v,visited[v].name,visited)
      end
      rec_buf[i]=(table.concat(rec_buf[i]))
      rec_buf[i]=" local "..visited[v].name.."="..rec_buf[i]..";"
     --print(rec_buf[i])
    end
    --form the rec_buf string
    rec_buf=table.concat(rec_buf)
    --process all values - shold be no recursion
    local buf={}
    for i=1,#arg do
      v=arg[i]
      --print(v)
      buf[i]={}
      if not recursive_proceed(v, buf[i], visited,i) then
        return nil, "Unserializable data in parameter #"..i
      end
    end
    
    if not visited.need_locals then -- no locals needed
      for i,v in ipairs(buf) do
        buf[i]=table.concat(buf[i])
      end
      if not visited.has_recursion then return "return "..table.concat(buf,",")
      else return "do "..rec_buf.." return "..table.concat(buf,",").." end" end
    end
    --else
    local lindex=0
    prevbuf={}
    for _,v in pairs(visited) do
      if type(v)=="table" and v.needs_declaration then --skip nontable fields(n, need_locals) and "normal" tables
        prevbuf[lindex] = " local "..v.name.."="..table.concat(buf[v.var_num],"",v.buf_start,v.buf_end)
        buf[v.var_num][v.buf_start]=v.name
        for i=v.buf_start+1,v.buf_end do
          buf[v.var_num][i]="" -- TODO Ugly, but works
        end
        lindex = lindex -1
      end
    end
    for i,v in ipairs(buf) do
      buf[i]=table.concat(buf[i])
    end
    return "do "..rec_buf..table.concat(prevbuf,";",lindex+1)..";return "..table.concat(buf,",",1).." end"
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
t1=nil
t2={2,3,4,5}
t3={t1,t2}
print(tserialize(t1,t2,t3))--]]


