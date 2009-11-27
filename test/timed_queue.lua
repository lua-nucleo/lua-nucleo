-- timed_queue.lua: tests for timed queue
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Add tests for invalid time of object to be inserted
-- TODO: Add tests for many objects
-- TODO: Port checker from priority queue
-- TODO: Test invalid time
-- TODO: Reject math.huge on put.
-- TODO: See TODOs in code!

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
      ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals'
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
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil) -- TODO: Non-empty queue should return object
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), nil) -- TODO: Math.huge!
end)

--------------------------------------------------------------------------------

test "single-element" (function()
  local timed_queue = assert_is_table(make_timed_queue())
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), nil)

  local time, value = 65, function() end

  timed_queue:insert(time, value)
  ensure_equals("no first if not enough time", timed_queue:pop_next_expired(50), nil)
  ensure_equals("valid expiration time", timed_queue:get_next_expiration_time(), time)

  local popped_time, popped_value = timed_queue:pop_next_expired(70)
  ensure_equals("popped time",  popped_time,  time)
  ensure_equals("popped value", popped_value, value)

  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), nil)
end)

-- TODO: Add more tests!

--------------------------------------------------------------------------------

assert(test:run())
