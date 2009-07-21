dofile("lua/import.lua")
local tdeepequals = assert(import "lua/tdeepequals.lua" {'tdeepequals'})
local tstr = assert(import "lua/tstr.lua" {'tstr'})
assert(type(tdeepequals) == "function")
local function check_ok(t1,t2,rez)
  assert(type(rez)=="boolean","Result type must be a number")
  local r=tdeepequals(t1,t2)
  print("First  = ",tstr(t1))
  print("Second = ",tstr(t2))
  print("Result = ",r)
  assert( r==rez, "Expected:"..tostring(rez))
end

return {check_ok=check_ok}