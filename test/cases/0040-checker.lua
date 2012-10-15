--------------------------------------------------------------------------------
-- 0040-checker.lua: tests for complex validation helper
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_returns,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_returns',
        'ensure_fails_with_substring'
      }

local make_checker,
      checker_exports
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

--------------------------------------------------------------------------------

local test = make_suite("checker", checker_exports)

--------------------------------------------------------------------------------

test:factory "make_checker" (make_checker)

--------------------------------------------------------------------------------

test:methods "msg"
             "result"

--------------------------------------------------------------------------------

test:method "good" (function()
  local checker = make_checker()

  print("checker", checker)

  ensure_equals("empty is good", checker:good(), true)
  ensure_equals("good have no messages", checker:msg(), "")
  ensure_returns(
      "good result is true",
      1, { true },
      checker:result()
    )
end)

--------------------------------------------------------------------------------

test:methods "ensure"

--------------------------------------------------------------------------------

test "ensure-passes" (function()
  local checker = make_checker()

  ensure_returns(
      "ensure returns arguments",
      3, { 42, nil, 24 },
      checker:ensure("my message", 42, nil, 24)
    )

  ensure_equals("still is good", checker:good(), true)
  ensure_equals("still have no messages", checker:msg(), "")
  ensure_returns(
      "result is true",
      1, { true },
      checker:result()
    )
end)

test:method "fail" (function()
  local checker = make_checker()

  ensure_equals("empty is good", checker:good(), true)

  checker:fail("my message 1")

  ensure_equals("1: fail is bad", checker:good(), nil)
  ensure_equals("1: fail message default", checker:msg(), "\nmy message 1")
  ensure_equals("1: fail message custom", checker:msg("p:", ":s"), "p:my message 1")
  ensure_returns("1: fail result default", 2, { nil, "\nmy message 1" }, checker:result())
  ensure_returns("1: fail result custom", 2, { nil, "p:my message 1" }, checker:result("p:", ":s"))

  checker:fail("my message 2")

  ensure_equals("2: fail is bad", checker:good(), nil)
  ensure_equals("2: fail message default", checker:msg(), "\nmy message 1\nmy message 2")
  ensure_equals("2: fail message custom", checker:msg("p:", ":s"), "p:my message 1:smy message 2")
  ensure_returns("2: fail result default", 2, { nil, "\nmy message 1\nmy message 2" }, checker:result())
  ensure_returns("2: fail result custom", 2, { nil, "p:my message 1:smy message 2" }, checker:result("p:", ":s"))
end)

test "ensure-fails" (function()
  local checker = make_checker()

  ensure_equals("empty is good", checker:good(), true)

  ensure_returns(
      "failed ensure still returns arguments with false",
      2, { false, 42 },
      checker:ensure("my message 1", false, 42)
    )

  ensure_equals("1: is bad", checker:good(), nil)
  ensure_equals("1: message default", checker:msg(), "\nmy message 1: 42")
  ensure_equals("1: message custom", checker:msg("p:", ":s"), "p:my message 1: 42")
  ensure_returns("1: result default", 2, { nil, "\nmy message 1: 42" }, checker:result())
  ensure_returns("1: result custom", 2, { nil, "p:my message 1: 42" }, checker:result("p:", ":s"))

  ensure_returns(
      "failed ensure still returns arguments with nil",
      3, { nil, nil, 42 },
      checker:ensure("my message 2", nil, nil, 42)
    )

  ensure_equals("2: is bad", checker:good(), nil)
  ensure_equals("2: message default", checker:msg(), "\nmy message 1: 42\nmy message 2: nil")
  ensure_equals("2: message custom", checker:msg("p:", ":s"), "p:my message 1: 42:smy message 2: nil")
  ensure_returns("2: result default", 2, { nil, "\nmy message 1: 42\nmy message 2: nil" }, checker:result())
  ensure_returns("2: result custom", 2, { nil, "p:my message 1: 42:smy message 2: nil" }, checker:result("p:", ":s"))
end)

test "ensure-fails-no-third-argument" (function()
  local checker = make_checker()

  ensure_equals("empty is good", checker:good(), true)

  ensure_returns(
      "failed ensure still returns arguments with false",
      1, { nil },
      checker:ensure("my message 1")
    )

  ensure_equals("1: is bad", checker:good(), nil)
  ensure_equals("1: message default", checker:msg(), "\nmy message 1: (no additional error message)")
  ensure_equals("1: message custom", checker:msg("p:", ":s"), "p:my message 1: (no additional error message)")
  ensure_returns("1: result default", 2, { nil, "\nmy message 1: (no additional error message)" }, checker:result())
  ensure_returns("1: result custom", 2, { nil, "p:my message 1: (no additional error message)" }, checker:result("p:", ":s"))
end)
