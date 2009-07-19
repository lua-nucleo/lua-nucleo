-- tdeepequals.lua: Test arbitrary lua tables for equality.
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local pairs, type, ipairs, tostring = pairs, type, ipairs, tostring
local table_concat, table_sort = table.concat, table.sort
local string_format, string_match = string.format,string.match

local tdeepequals
do
  local p_table -- table, containing hashes of pointer-like data - functions, threads, userdata


  ------------------------------------------------------------
  --------------------  UTILITY FUNCTIONS  -------------------
  ------------------------------------------------------------

  --1.make a duplicate(copy) of a table
  local function table_dup(t)
    assert(type(t)=="table")
    local td={}
    for k,v in pairs(t) do
      td[k]=v
    end
    return td
  end

  --2.Generic more(for strings and numbers)
  local function more(t1,t2)
    if t1>t2 then
      return 1
    elseif t1<t2 then
      return -1
    else
      return 0
    end
  end

  --3.Boolean more(for strings and numbers)
  local function bool_more(t1,t2)
    if not t1 and  t2 then
      return -1
    end
    if not t1 and  not t2 or t1 and t2 then
      return 0
    end
    return 1
  end

  --3.More for threads, functions and userdata(using hash table p_table) and also nil
  local function p_more(t1,t2)
    if not t1 and not t2 then
      return 0
    end
    if not t1 then
      return -1
    end
    if not t2 then
      return 1
    end
    if not p_table[t1] then
      p_table.n=p_table.n+1
      p_table[t1]=p_table.n
    end
    if not p_table[t2] then
      p_table.n=p_table.n+1
      p_table[t2]=p_table.n
    end
    return (p_table[t1]-p_table[t2])
  end

  --4.Compare (less) utility for boolean
  local function bool_comp(t1,t2)
    return not t1 and  t2
  end

  --5.Compare (less) utility for userdata, threads, functions
  local function p_comp(t1,t2)
    return p_more(t1,t2)<0
  end


  --6. Compare (less) utility generator for tables
  local tmore --more for tables, will be described later
  local function table_comp(visited)
    return function(t1,t2)
      local vis1=table_dup(visited)
      local vis2=table_dup(visited)
      local m=tmore(t1[1],t2[1],vis1,vis2)
      if m==0 then
        m = tmore(t1[2],t2[2],vis1,vis2)
      end
      return m<0
    end
  end
  ------------------------------------------------------------
  ------------------------  MAIN WORK  -----------------------
  ------------------------------------------------------------

  --for a given table returns a number of sorted arrays -
  --ikeys contains integer keys etc.
  --tkeys contains sorted {key,value} pairs in which key is a table
  --visited is a hash of already visited tables - used to cope with
  --recursive tables and tables having shared sub_tables:
  --e.g. 1 (recursive): local t={} t[t]=1
  --e.g. 2 (shared)   : local t1={} local t={t1,t1}
  local function analyze (t,visited)
    local ikeys={};
    local strkeys={};
    local boolkeys={}
    local tkeys={};
    local pkeys={};
    for k, v in pairs(t) do
      local k_type = type(k)
      if k_type=="number" then
        ikeys[#ikeys + 1] = k
      elseif k_type=="string" then
        strkeys[#strkeys + 1] = k
      elseif k_type=="boolean" then
        boolkeys[#boolkeys + 1] = k
      elseif k_type=="table" then
        local ind=#tkeys + 1
        tkeys[ind]={}
        tkeys[ind][1] = k
        tkeys[ind][2] = t[k]
      else
        pkeys[#pkeys + 1] = k
      end
    end
    table_sort(ikeys);
    table_sort(strkeys);
    table_sort(boolkeys,bool_comp);
    table_sort(pkeys,p_comp)
    return ikeys, strkeys,boolkeys, pkeys, tkeys;
  end

  local function pr(t)
    local buf="{"
    for k,v in pairs(t) do
      buf = buf.."["..tostring(k).."]".."="..tostring(v)..","
    end
    buf = buf.."}"
    return buf
  end
  -- compares two generic pieces of lua data - first and second
  -- vis1 and vis2 are hashes of visited tables for first and second
  tmore = function (first,second,vis1,vis2)
    --[[print(first,"=",tserialize(first),pr(vis1))
    print(second,"=",tserialize(second),pr(vis2))
    print ()--]]
    local type1, type2 = type(first), type(second)
    if type1~=type2 then
      return more(type1,type2)
    else
      if type1=="number" or type1=="string" then
        return more(first,second)
      elseif type1=="boolean" then
        return bool_more(first,second)
      elseif type1=="table" then
        if vis1[first] and vis2[second] then
          return more(vis1[first], vis2[second])
        end
        if vis1[first] then
          return 1
        end
        if vis2[second] then
          return -1
        end
        vis1.n=vis1.n+1
        vis1[first]=vis1.n
        vis2.n=vis2.n+1
        vis2[second]=vis2.n
        local ikeys1, strkeys1,boolkeys1, pkeys1, tkeys1 = analyze(first,vis1)
        local ikeys2, strkeys2,boolkeys2, pkeys2, tkeys2 = analyze(second,vis2)
        local i
        local m
        -- numeric keys
        i=1
        if ikeys1 or ikeys2 then
          while i<=#ikeys1 and i<=#ikeys2 do
            m=more(ikeys1[i],ikeys2[i])
            if m~=0 then
              return m
            end
            m=tmore(first[ikeys1[i]],second[ikeys2[i]],vis1,vis2)
            if m~=0 then
              return m
            end
            i = i+1
          end
          m=more(#ikeys1-i,#ikeys2-i)
          if m~=0 then
            return m
          end
        end
        -- string keys
        if strkeys1 or strkeys2 then
          i=1
          while i<=#strkeys1 and i<=#strkeys2 do
            local m=more(strkeys1[i],strkeys2[i])
            if m~=0 then
              return m
            end
            m=tmore(first[strkeys1[i]],second[strkeys2[i]],vis1,vis2)
            if m~=0 then
              return m
            end
            i = i+1
          end
          m=more(#strkeys1-i,#strkeys2-i)
          if m~=0 then
            return m
          end
        end
        -- bool keys
        if boolkeys1 or boolkeys2 then
          i=1
          while i<=#boolkeys1 and i<=#boolkeys2 do
            local m=bool_more(boolkeys1[i],boolkeys2[i])
            if m~=0 then
              return m
            end
            m=tmore(first[boolkeys1[i]],second[boolkeys2[i]],vis1,vis2)
            if m~=0 then
              return m
            end
            i = i+1
          end
          m=more(#boolkeys1-i,#boolkeys2-i)
          if m~=0 then
            return m
          end
        end
        -- p keys(userdata, functions, etc
        if pkeys1 or pkeys2 then
          i=1
          while i<=#pkeys1 and i<=#pkeys2 do
            local m=p_more(pkeys1[i],pkeys2[i])
            if m~=0 then
              return m
            end
            m=tmore(first[pkeys1[i]],second[pkeys2[i]],vis1,vis2)
            if m~=0 then
              return m
            end
            i = i+1
          end
          m=more(#pkeys1-i,#pkeys2-i)
          if m~=0 then
            return m
          end
        end
        -- table keys
        if tkeys1 or tkeys2 then
          table_sort(tkeys1,table_comp(vis1));
          table_sort(tkeys2,table_comp(vis2));
          i=1
          while i<=#tkeys1 and i<=#tkeys2 do
            local m=tmore(tkeys1[i][1],tkeys2[i][1],vis1,vis2)
            if m~=0 then
              return m
            end
            m=tmore(tkeys1[i][2],tkeys2[i][2],vis1,vis2)
            if m~=0 then
              return m
            end
            i = i+1
          end
          m=more(#tkeys1-i,#tkeys2-i)
          if m~=0 then
            return m
          end
        end
        return 0
      else -- userdata, thread, function
        return p_more(first,second)
      end
    end
  end

  tdeepequals = function(t1,t2)
    p_table={n=0}
    local r = tmore(t1,t2,{n=0},{n=0})
    p_table=nil
    return r
  end
end

return
{
  tdeepequals = tdeepequals
}