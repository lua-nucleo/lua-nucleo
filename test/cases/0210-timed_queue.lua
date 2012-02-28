--------------------------------------------------------------------------------
-- 0210-timed_queue.lua: tests for timed queue
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Add more tests?

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

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

test:factory "make_timed_queue" (make_timed_queue)
test:methods "pop_next_expired"
             "get_next_expiration_time"
             "insert"
--------------------------------------------------------------------------------

test "empty" (function()
  local timed_queue = ensure("created timed queue", make_timed_queue())
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
  ensure_equals("no expiration time", timed_queue:get_next_expiration_time(), math.huge)
end)

--------------------------------------------------------------------------------

test "cant-insert-huge" (function()
  local timed_queue = make_timed_queue()
  ensure_fails_with_substring(
      "can't insert huge",
      function() timed_queue:insert(math.huge, "value") end,
      "infinite time is not supported"
    )
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
end)

--------------------------------------------------------------------------------

test "cant-insert-negative" (function()
  local timed_queue = make_timed_queue()
  ensure_fails_with_substring(
      "can't insert negative",
      function() timed_queue:insert(-1, "value") end,
      "negative time is not supported"
    )
  ensure_equals("no elements", timed_queue:pop_next_expired(math.huge), nil)
end)

--------------------------------------------------------------------------------

test "single-element" (function()
  local timed_queue = make_timed_queue()
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
  local timed_queue = make_timed_queue()
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

--------------------------------------------------------------------------------

test "pop-strange-times" (function()
  local timed_queue = make_timed_queue()

  timed_queue:insert(1, "a")

  ensure_equals(
      "negative",
      timed_queue:pop_next_expired(-1),
      nil
    )

  ensure_equals(
      "zero",
      timed_queue:pop_next_expired(0),
      nil
    )

  ensure_tequals(
      "popped",
      { timed_queue:pop_next_expired(1) },
      { 1, "a" }
    )

  ensure_equals(
      "no more",
      timed_queue:pop_next_expired(1),
      nil
    )
end)

--------------------------------------------------------------------------------

test "insert-pop-insert" (function()
  local timed_queue = make_timed_queue()

  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      math.huge
    )

  timed_queue:insert(1, "a")
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      1
    )

  timed_queue:insert(0.5, "b")
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      0.5
    )

  timed_queue:insert(1.5, "c")
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      0.5
    )

  ensure_tequals(
      "pop",
      { timed_queue:pop_next_expired(1) },
      { 0.5, "b" }
    )
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      1
    )

  ensure_tequals(
      "pop",
      { timed_queue:pop_next_expired(math.huge) },
      { 1, "a" }
    )
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      1.5
    )

  ensure_tequals(
      "pop",
      { timed_queue:pop_next_expired(1.5) },
      { 1.5, "c" }
    )
  ensure_equals(
      "expiration time",
      timed_queue:get_next_expiration_time(),
      math.huge
    )

  ensure_tequals(
      "pop",
      { timed_queue:pop_next_expired(math.huge) },
      { nil }
    )
end)

--------------------------------------------------------------------------------

assert(test:run())
