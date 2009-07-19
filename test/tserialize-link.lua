dofile("lua/strict.lua")
dofile("lua/import.lua")
local make_suite = select(1, ...)
assert(type(make_suite) == "function")
local check_ok = import 'test/tserialize-test-utils.lua' { 'check_ok' }
-- ----------------------------------------------------------------------------
-- Link tests
-- ----------------------------------------------------------------------------
local test = make_suite("syntetic link tests")
test "1" (function()
  local a={}
  local b={a}
  check_ok(a,b)
end)
test "2" (function()
  local a={}
  local b={a}
  local c={b}
  check_ok(a,b,c)
end)
test "3" (function()
  local a={1,2,3}
  local b={[true]=a}
  local c={[true]=a}
  check_ok(a,b,c)
end)
test "4" (function()
  local a={1,2,3}
  local b={a,a,a,a}
  local c={a}
  check_ok(a,b,c)
end)
test "5" (function()
  local t1={}
  local t2={}
  t1[t1]=t2
  local u={t1,t2}
  check_ok(u)
end)
test "6" (function()
  local a={}
  a[a]=a a[{a,a}]={a,a} a[3]={ {a,{a,{a}},{[a]=a}} }
  check_ok(a)
end)
assert (test:run())