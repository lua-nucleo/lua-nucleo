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
local test = make_suite("basic types")
test "1" ( function() check_ok(1,1,0) end)
test "2" ( function() check_ok(1,0,1) end)
test "3" ( function() check_ok(1,"",1) end)
test "4" ( function() check_ok("1","",1) end)
test "5" ( function() check_ok("1",function () end,1) end)

test "6" ( function()
  local t=function () end
  check_ok(t,t,0)
end)

test "7" ( function() check_ok(true,true,0) end)

test "8" ( function()
  local t=function () end
  check_ok(true,t,1)
end)

test "9" ( function() check_ok(true,{},1) end)

test "10" ( function()
  local t=function () end
  check_ok(t,{},1)
end)

assert (test:run())
