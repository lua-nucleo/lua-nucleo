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
local test = make_suite("basic tables")
test "1" ( function() check_ok({},{},0) end)
test "2" ( function() check_ok({1},{2},1) end)
test "3" ( function() check_ok({1,2},{2,1},1) end)
test "4" ( function() check_ok({1,2,4,7},{1,2,4,7},0) end)
test "5" ( function() check_ok({1,2,{1,2}},{1,{1,2},2},1) end)
do
  local t1={[{}]=1,[{}]=2}
  local t2={[{}]=2,[{}]=1}
  test "6" ( function() check_ok(t1,t2,0) end)
end
do
  local t1={[{}]=1,[{}]=2}
  local t2={[{}]=1,[{}]=1}
  test "7" ( function() check_ok(t1,t2,1) end)
end

do
  local t1={[{1,2}]=1,[{1,2}]=1}
  local t2={[{1,2}]=1,[{1,2}]=1}
  test "8" ( function() check_ok(t1,t2,0) end)
end

do
  local t1={[{1,2,[{true}]=4}]=3,[{1,2,[{1}]=2}]=2,[{1,2}]=1}
  local t2={[{1,2}]=1,[{1,2,[{1}]=2}]=2,[{1,2,[{true}]=4}]=3}
  test "8" ( function() check_ok(t1,t2,0) end)
end

do
  local t1={[{1,2,[{true}]=4}]=3,[{1,2,[{1}]=2}]=2,[{1,2}]=1}
  local t2={[{1,2}]=1,[{1,2,[{2}]=2}]=2,[{1,2,[{true}]=4}]=3}
  test "9" ( function() check_ok(t1,t2,1) end)
end


assert (test:run())
