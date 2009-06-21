-- import.lua -- tests for import module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua/strict.lua') -- Import module requires strict
dofile('lua/import.lua') -- Import module should be loaded manually

assert(pcall(function() import() end) == false)
assert(pcall(function() import 'badfile' end) == false)
assert(pcall(function() import 'test/data/import/bad.lua' end) == false)

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
  local t = assert(import 'test/data/import/good.lua' ())
  assert(type(t) == "table")
  assert(type(t.x) == "table")
  assert(t.a == 1)

  do
    local t2 = import 'test/data/import/good.lua'
    assert(type(t2) == "table")
    assert(type(t2.x) == "table")
    assert(t2.a == 1)

    local x, a, t3 = t2 {'x', 'a'}
    assert(type(x) == "table")
    assert(a == 1)
    assert(t2 == t3)
  end

  do
    local y, z = import 'test/data/import/good.lua' ()
    assert(y == t)
    assert(z == nil)
  end

  do
    local x, y, z = import 'test/data/import/good.lua' 'x'
    assert(x == t.x)
    assert(y == t)
    assert(z == nil)
  end

  do
    local x, y, z = import 'test/data/import/good.lua' {'x'}
    assert(x == t.x)
    assert(y == t)
    assert(z == nil)
  end

  do
    local x, a, y, z = import 'test/data/import/good.lua' {'x', 'a'}
    assert(x == t.x)
    assert(a == t.a)
    assert(y == t)
    assert(z == nil)
  end

  assert(pcall(function() import 'test/data/import/good.lua' 'y' end) == false)
  assert(pcall(function() import 'test/data/import/good.lua' {'y'} end) == false)
  assert(pcall(function() import 'test/data/import/good.lua' {'y', 'x'} end) == false)
  assert(pcall(function() import 'test/data/import/good.lua' {'x', 'y'} end) == false)
end
