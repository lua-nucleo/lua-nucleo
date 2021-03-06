--------------------------------------------------------------------------------
-- 0204-tdeepequals-userdata-functions-threads.lua:
-- tests for support of nonstandard types in tdeepequals
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local unpack = unpack or table.unpack
local newproxy = newproxy or select(
    2,
    unpack({
        xpcall(require, function() end, 'newproxy')
      })
  )

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local check_ok =
  import 'test/test-lib/tdeepequals-test-utils.lua' { 'check_ok' }

local collect_all_garbage =
  import 'lua-nucleo/misc.lua' { 'collect_all_garbage' }

---------------------------------------------------------------------------

local test = make_suite("userdata, functions, threads")

---------------------------------------------------------------------------

test:BROKEN_IF(not newproxy) "1" (function()
  local changed = 0
  local mt = {__gc = function() changed = 1 end}
  local userdata1 = newproxy()
  debug.setmetatable(userdata1, mt)
  local userdata2 = newproxy()
  debug.setmetatable(userdata2, mt)
  local u={userdata1, userdata2}
  local v={userdata2, userdata1}
  check_ok(u, v, false)
  userdata1 = nil
  userdata2 = nil
  u = nil
  v = nil
  collect_all_garbage()
  assert(changed == 1,"Garbage not collected!!!")
end)

test:BROKEN_IF(not newproxy) "2" (function()
  local userdata1 = newproxy()
  local userdata2 = newproxy() -- TODO: typo below or forgotten copy-paste?
  local u = {userdata1,userdata1}
  local v = {userdata1,userdata1}
  check_ok(u, v, true)
end)

test:BROKEN_IF(not newproxy) "3" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local u = {udt}
  local v = {thr}
  check_ok(u, v, false)
end)

test:BROKEN_IF(not newproxy) "4" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u = {udt}
  local v = {fnc}
  check_ok(u, v, false)
end)

test:BROKEN_IF(not newproxy) "5" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u = {[udt] = fnc}
  local v = {[fnc] = thr}
  check_ok(u, v, false)
end)

test:BROKEN_IF(not newproxy) "6" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local u = {[udt] = thr, [thr] = udt}
  local v = {[thr] = udt, [udt] = thr}
  check_ok(u, v, true)
end)

test:BROKEN_IF(not newproxy) "7" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u = {[udt] = fnc, [fnc]=udt, [thr]=udt}
  local v = {[fnc] = udt, [thr]=udt, [udt]=fnc}
  check_ok(u, v, true)
end)

test:BROKEN_IF(not newproxy) "8" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u = {[{}] = thr, [{}] = udt, [{}] = fnc}
  local v = {[{}] = udt, [{}] = fnc, [{}] = thr}
  check_ok(u, v, true)
end)

test:BROKEN_IF(not newproxy) "9" (function()
  local udt = newproxy()
  local thr = coroutine.create(function() end)
  local fnc = function() end
  local u = {[{}] = thr, [{}] = thr, [{}] = fnc}
  local v = {[{}] = udt, [{}] = fnc, [{}] = thr}
  check_ok(u, v, false)
end)
