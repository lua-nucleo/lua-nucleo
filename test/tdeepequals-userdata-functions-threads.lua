dofile("lua/strict.lua")
dofile("lua/import.lua")
local tdeepequals = assert(import "lua/tdeepequals.lua" {'tdeepequals'})
local tstr = assert(import "lua/tstr.lua" {'tstr'})
assert(type(tdeepequals) == "function")

local function check_ok(t1,t2,rez)
  assert(type(rez)=="number","Result type must be a number")
  local r=assert(tdeepequals(t1,t2))
  print("First  = ",tstr(t1))
  print("Second = ",tstr(t2))
  print("Result = ",r)
  assert( r==0 and rez==0 or r~=0 and rez~=0, "Expected:"..rez)
end

local make_suite = select(1, ...)
assert(type(make_suite) == "function")
-- ----------------------------------------------------------------------------
-- Basic tests
-- ----------------------------------------------------------------------------
local test = make_suite("userdata,functions, threads")

test "1" ( function()
  local changed=0
  local mt={__gc=function() changed = 1 end}
  local userdata1 = newproxy()
  debug.setmetatable(userdata1,mt)
  local userdata2 = newproxy()
  debug.setmetatable(userdata2,mt)
  local u={userdata1,userdata2}
  local v={userdata2,userdata1}
  check_ok(u,v,1)
  userdata1=nil
  userdata2=nil
  u=nil
  v=nil
  collectgarbage("collect")
  assert(changed==1,"Garbage not collected!!!")
end)

test "2" ( function()
  local userdata1 = newproxy()
  local userdata2 = newproxy()
  local u={userdata1,userdata1}
  local v={userdata1,userdata1}
  check_ok(u,v,0)
end)

test "3" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local u={udt}
  local v={thr}
  check_ok(u,v,1)
end)

test "4" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u={udt}
  local v={fnc}
  check_ok(u,v,1)
end)

test "5" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u={[udt]=fnc}
  local v={[fnc]=thr}
  check_ok(u,v,1)
end)

test "6" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local u={[udt]=thr,[thr]=udt}
  local v={[thr]=udt,[udt]=thr}
  check_ok(u,v,0)
end)

test "7" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u={[udt]=fnc,[fnc]=udt,[thr]=udt}
  local v={[fnc]=udt,[thr]=udt,[udt]=fnc}
  check_ok(u,v,0)
end)

test "8" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u={[{}]=thr,[{}]=udt,[{}]=fnc}
  local v={[{}]=udt,[{}]=fnc,[{}]=thr}
  check_ok(u,v,0)
end)

test "9" ( function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u={[{}]=thr,[{}]=thr,[{}]=fnc}
  local v={[{}]=udt,[{}]=fnc,[{}]=thr}
  check_ok(u,v,1)
end)



assert (test:run())