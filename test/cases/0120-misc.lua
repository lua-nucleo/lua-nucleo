--------------------------------------------------------------------------------
-- 0120-misc.lua: tests for various useful stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local newproxy = newproxy

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

--------------------------------------------------------------------------------

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

local tcount_elements
      = import 'lua-nucleo/table.lua'
      {
        'tcount_elements'
      }

local unique_object,
      collect_all_garbage,
      misc
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object',
        'collect_all_garbage'
      }

--------------------------------------------------------------------------------

local test = make_suite("misc", misc)

--------------------------------------------------------------------------------

-- fails on Lua 5.2 and sometimes on Lua 5.3
-- see https://github.com/lua-nucleo/lua-nucleo/issues/57
test:test_for("unique_object"):BROKEN_IF(LUA52 or LUA53) (function()
  -- A bit silly, but how to test it better?
  local N = 100

  local data = { }
  for i = 1, N do
    data[unique_object()] = true
  end

  local count = 0
  for k, v in pairs(data) do
    count = count + 1
  end

  ensure_equals("all objects are unique", count, N)
end)

--------------------------------------------------------------------------------

test:group 'collect_all_garbage'

--------------------------------------------------------------------------------

test 'collect_all_garbage-table' (function()
  local cache = setmetatable({ }, { __mode = "k" })

  collect_all_garbage()

  do
    local t = { }
    cache[t] = true

    ensure_equals("all objects are cached", tcount_elements(cache), 1)
  end

  collect_all_garbage()

  ensure_equals("no objects are cached", tcount_elements(cache), 0)
end)

test 'collect_all_garbage-userdata' (function()
  local cache = setmetatable({ }, { __mode = "k" })
  local userdata_collected = false

  collect_all_garbage()

  do
    -- No garbage except our userdata.
    -- Checking that both userdata GC cycles would be run
    local obj, setmetatable =
      newproxy and newproxy() or { },
      newproxy and debug.setmetatable or setmetatable
    setmetatable(obj, { __gc = function() userdata_collected = true end })
    cache[obj] = true

    ensure_equals("userdata not collected", userdata_collected, false)
    ensure_equals("all objects are cached", tcount_elements(cache), 1)

    collect_all_garbage()

    ensure_equals("userdata not collected", userdata_collected, false)
    ensure_equals("all objects are cached", tcount_elements(cache), 1)
  end

  collect_all_garbage()

  ensure_equals("userdata is collected", userdata_collected, true)
  ensure_equals("no objects are cached", tcount_elements(cache), 0)
end)

test 'collect_all_garbage-complex' (function()
  local cache = setmetatable({ }, { __mode = "k" })
  local userdata_collected = false

  collect_all_garbage()

  do
    local t = { }
    cache[t] = true

    local obj, setmetatable =
      newproxy and newproxy() or { },
      newproxy and debug.setmetatable or setmetatable
    setmetatable(obj, { __gc = function() userdata_collected = true end })
    cache[obj] = true

    ensure_equals("userdata not collected", userdata_collected, false)
    ensure_equals("all objects are cached", tcount_elements(cache), 2)
  end

  collect_all_garbage()

  ensure_equals("userdata is collected", userdata_collected, true)
  ensure_equals("no objects are cached", tcount_elements(cache), 0)
end)
