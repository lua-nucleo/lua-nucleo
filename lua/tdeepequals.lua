-- tdeepequals.lua: Test arbitrary lua tables for equality.
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local pairs, type, ipairs, tostring = pairs, type, ipairs, tostring
local table_concat, table_sort = table.concat, table.sort
local string_format, string_match = string.format,string.match

local function table_dup(t)
  assert(type(t)=="table")
  local td={}
  for k,v in pairs(t) do
    td[k]=v
  end
  td.n=t.n
  return td
end


local function more(t1,t2)
  if t1>t2 then
    return 1
  elseif t1<t2 then
    return -1
  else
    return 0
  end
end

local tmore

local function table_comp(visited)
  return function(t1,t2)
    vis1=table_dup(visited)
    vis2=table_dup(visited)
    local m=tmore(t1[1],t2[1],vis1,vis2)
    if m==0 then
      vis1=table_dup(visited)
      vis2=table_dup(visited)
      m = tmore(t1[2],t2[2],vis1,vis2)
    end
    return m<0
  end
end


local function analyze (t,visited)
  --print(t,visited,visited.n)
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
  table_sort(boolkeys,tostring_comp);
  table_sort(pkeys,tostring_comp)
  table_sort(tkeys,table_comp(visited));
  return ikeys, strkeys,boolkeys, pkeys, tkeys;
end
tmore = function (first,second,vis1,vis2)
  local type1, type2 = type(first), type(second)
  if type1~=type2 then
    return more(type1,type2)
  else
    if type1=="number" or type1=="string" then
      return more(first,second)
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
      -- numeric keys
      i=1
      if ikeys1 or ikeys2 then
	while i<=#ikeys1 and i<=#ikeys2 do
	  local m=more(ikeys1[i],ikeys2[i])
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
      end
      -- bool keys
      i=1
      if boolkeys1 or boolkeys2 then
	while i<=#boolkeys1 and i<=#boolkeys2 do
	  local m=more(tostring(boolkeys1[i]),tostring(boolkeys2[i]))
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
	  local m=more(tostring(pkeys1[i]),tostring(pkeys2[i]))
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
    else
      return more(tostring(first),tostring(second))
    end
  end
end


dofile("lua/import.lua")
local tserialize = import 'lua/tserialize.lua' {'tserialize'}


local t1={1,2,{1,2,3}}
local t2={1,2,2}
visited1={};
visited2={};
print(tserialize(t1),tserialize(t2), tmore(t1,t2,{n=0},{n=0}))

t1={}
t2={}
t3={}
t4={}
u={t1,t2,{t1,t2}}
v={t3,t4,{t4,t3}}

print(tserialize(u),tserialize(v), tmore(u,v,{n=0},{n=0}))
