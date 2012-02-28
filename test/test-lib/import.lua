--------------------------------------------------------------------------------
-- import.lua: generates list of test files to be run
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local test_import = function(BASE_PATH)
  assert(pcall(function() import() end) == false)
  assert(pcall(function() import 'badfile' end) == false)
  assert(pcall(function() import(BASE_PATH..'import/bad.lua') end) == false)

  do
    local t = {x = {}, a = 1}

    do
      local y, z = import(t) ()
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, y, z = import(t) 'x'
      assert(x == t.x)
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, y, z = import(t) {'x'}
      assert(x == t.x)
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, a, y, z = import(t) {'x', 'a'}
      assert(x == t.x)
      assert(a == t.a)
      assert(y == t)
      assert(z == nil)
    end

    assert(pcall(function() import(t) 'y' end) == false)
    assert(pcall(function() import(t) {'y'} end) == false)
    assert(pcall(function() import(t) {'y', 'x'} end) == false)
    assert(pcall(function() import(t) {'x', 'y'} end) == false)
  end

  do
    local t = assert(import(BASE_PATH..'import/good.lua') ())
    assert(type(t) == "table")
    assert(type(t.x) == "table")
    assert(t.a == 1)

    do
      local y, z = import(BASE_PATH..'import/good.lua') ()
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, y, z = import(BASE_PATH..'import/good.lua') 'x'
      assert(x == t.x)
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, y, z = import(BASE_PATH..'import/good.lua') {'x'}
      assert(x == t.x)
      assert(y == t)
      assert(z == nil)
    end

    do
      local x, a, y, z = import(BASE_PATH..'import/good.lua') {'x', 'a'}
      assert(x == t.x)
      assert(a == t.a)
      assert(y == t)
      assert(z == nil)
    end

    assert(pcall(function() import(BASE_PATH..'import/good.lua') 'y' end) == false)
    assert(pcall(function()
        import(BASE_PATH..'import/good.lua') {'y'} end
      ) == false)
    assert(pcall(function()
        import(BASE_PATH..'import/good.lua') {'y', 'x'} end
      ) == false)
    assert(pcall(function()
        import(BASE_PATH..'import/good.lua') {'x', 'y'} end
      ) == false)

    assert(pcall(function()
        import(BASE_PATH..'import/circular-A.lua') () end
      ) == false)

    assert(pcall(function()
        import(BASE_PATH..'import/circular-self.lua') () end
      ) == false)
  end
end

return
{
  test_import = test_import;
}
