local make_suite = select(1, ...)
assert(type(make_suite) == "function")
local check_ok , check_ok_link = import 'test/tserialize-test-utils.lua' { 'check_ok' , 'check_ok_link'}
-- ----------------------------------------------------------------------------
-- Link tests
-- ----------------------------------------------------------------------------
local test = make_suite("syntetic link tests")
test "1" (function()
  do
    local a={}
    local b={a}
    check_ok_link({{"[1]","[2][1]"}},a,b)
  end
end)
test "2" (function()
  do
    local a={}
    local b={a}
    local c={b}
    check_ok_link({{"[1]","[2][1]"},{"[2]","[3][1]"},{"[1]","[3][1][1]"}},a,b,c)
  end
end)
test "3" (function()
  do
    local a={1,2,3}
    local b={[true]=a}
    local c={[true]=a}
    check_ok_link({{"[1]","[2][true]"},{"[1]","[3][true]"},{"[2][true]","[3][true]"}},a,b,c)
  end
end)
test "4" (function()
  do
    local a={1,2,3}
    local b={a,a,a,a}
    local c={a}
    check_ok_link({{"[1]","[2][1]"},{"[1]","[2][2]"},{"[1]","[2][3]"},{"[1]","[2][4]"},{"[3][1]","[1]"}},a,b,c)
  end
end)

assert (test:run())