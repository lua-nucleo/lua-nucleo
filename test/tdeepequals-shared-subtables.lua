dofile("lua/strict.lua")
dofile("lua/import.lua")
local tdeepequals = assert(import "lua/tdeepequals.lua" {'tdeepequals'})
local tserialize = assert(import "lua/tserialize.lua" {'tserialize'})
assert(type(tdeepequals) == "function")

local function check_ok(t1,t2,rez)
  assert(type(rez)=="number","Result type must be a number")
  local r=assert(tdeepequals(t1,t2))
  print("First  = ",tserialize(t1))
  print("Second = ",tserialize(t2))
  print("Result = ",r)
  assert( r==0 and rez==0 or r~=0 and rez~=0, "Expected:"..rez)
end


local make_suite = select(1, ...)
assert(type(make_suite) == "function")
-- ----------------------------------------------------------------------------
-- Basic tests
-- ----------------------------------------------------------------------------
local test = make_suite("shared subtables and recursion")
test "1" ( function()
  local t1={}
  local t2={}
  local t3={}
  local t4={}
  local u={t1,t2,[t1]=t1,[t2]=t2}
  local v={t3,t4,[t4]=t4,[t3]=t3}
  check_ok(u,v,0)
end)

test "2" ( function()
  local t1={}
  local t2={}
  local t3={}
  local t4={}
  local u={{{{t1}}},{{{t2}}},[t1]=t1,[t2]=t2}
  local v={{{{t3}}},{{{t4}}},[t4]=t4,[t3]=t3}
  check_ok(u,v,0)
end)

test "3" ( function()
  local t1={}
  local t2={}
  local t3={}
  local t4={}
  local u={{{{t1}}},{t2},[t1]=t1,[t2]=t2}
  local v={{{{t3}}},{t4},[t4]=t4,[t3]=t3}
  check_ok(u,v,0)
end)

test "4" ( function()
  local t1={}
  local t2={}
  local t3={}
  local t4={}
  local u={t1,t2,[t1]=t2,[t2]=t1}
  local v={t3,t4,[t3]=t3,[t4]=t4}
  check_ok(u,v,1)
end)

test "5" ( function()
  local u={}
  local v={}
  u[u]=u
  v[v]=v
  check_ok(u,v,0)
end)

test "6" ( function()
  local u={}
  local v={}
  u[v]=u
  v[u]=v
  check_ok(u,v,0)
end)

test "7" ( function()
  local t1={}
  local t2={}
  t1[t1]=t2
  local t3={}
  local u={t2,t1}
  local v={t3,t1}
  check_ok(u,v,1)
end)

test "8" ( function()
  local t1={}
  local t2={}
  t1[t1]=t2
  local t3={}
  local t4={}
  t3[t3]=t3
  local u={t1,t2}
  local v={t3,t4}
  check_ok(u,v,1)
end)

test "9" ( function()
  local a={1,2,3}
  local u={[a]=a,[{a,a}]={a,a}, { {a,{a,{a}},{[a]=a}} } }
  check_ok(u,u,0)
end)

test "10" ( function()
  local a={1,2,3}
  local u={[a]=a,[{a,a}]={a,a}, { {a,{a,{a}},{[a]=a}} } }
  local v={[a]=a,[{a,a}]={a,a}, { {a,{a,{{a}}},{[a]=a}} } }
  check_ok(u,v,1)
end)

test "10" ( function()
  local a={}
  a[a]=a a[{a,a}]={a,a} a[3]={ {a,{a,{a}},{[a]=a}} }
  local b={}
  b[b]=b b[{b,b}]={b,b,b} b[3]={ {b,{b,{b}},{[b]=b}} }
  check_ok(a,b,1)
end)

assert (test:run())