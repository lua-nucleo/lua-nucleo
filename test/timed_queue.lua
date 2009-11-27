-- timed_queue.lua: tests for timed queue
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Add tests for invalid time of object to be inserted
-- TODO: Add tests for many objects
-- TODO: Port checker from priority queue
-- TODO: Test invalid time
-- TODO: Reject math.huge on put.

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local assert_is_table,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_number'
      }

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local tdeepequals,
      tstr
      = import 'lua-nucleo/table.lua'
      {
        'tdeepequals',
        'tstr'
      }

local make_timed_queue,
      timed_queue_exports
      = import 'lua-nucleo/timed_queue.lua'
      {
        'make_timed_queue'
      }

--------------------------------------------------------------------------------

local test = make_suite("timed_queue", timed_queue_exports)

--------------------------------------------------------------------------------

test:group "make_timed_queue"

--------------------------------------------------------------------------------

test "empty" (function()
  local timed_queue = make_timed_queue()
  ensure("created timed queue", timed_queue)
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)
end)

--------------------------------------------------------------------------------

test "cant-insert-huge" (function()
  local timed_queue = assert_is_table(make_timed_queue())
  ensure_fails_with_substring(
      "can't insert huge",
      function() timed_queue:insert(math.huge, "value") end,
      "infinite time is not supported"
    )
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
end)

--------------------------------------------------------------------------------

test "cant-insert-negative" (function()
  local timed_queue = assert_is_table(make_timed_queue())
  ensure_fails_with_substring(
      "can't insert negative",
      function() timed_queue:insert(-1, "value") end,
      "negative time is not supported"
    )
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
end)

--------------------------------------------------------------------------------

test "single-element" (function()
  local timed_queue = assert_is_table(make_timed_queue())
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)

  local time, value = 65, function() end

  timed_queue:insert(time, value)
  ensure_equals("no first if not enough time", timed_queue:pop_next_expired(time - 1), nil)
  ensure_equals("valid expiration time", timed_queue:get_next_expiration_time(), time)

  ensure_tequals("pop_next_expired", { timed_queue:pop_next_expired(time) }, { time, value })

  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)
end)

test "single-element-huge" (function()
  local timed_queue = assert_is_table(make_timed_queue())
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)

  local time, value = 65, function() end

  timed_queue:insert(time, value)
  ensure_equals("no first if not enough time", timed_queue:pop_next_expired(time - 1), nil)
  ensure_equals("valid expiration time", timed_queue:get_next_expiration_time(), time)

  ensure_tequals("pop_next_expired", { timed_queue:pop_next_expired(math.huge) }, { time, value })

  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)
end)

-- TODO: Add more tests!

--------------------------------------------------------------------------------

assert(test:run())
