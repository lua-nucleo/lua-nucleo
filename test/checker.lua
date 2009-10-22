-- checker.lua: tests for complex validation helper
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

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

local make_checker,
      checker_exports
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

--------------------------------------------------------------------------------

local test = make_suite("checker", checker_exports)

--------------------------------------------------------------------------------

test:group "make_checker"

--------------------------------------------------------------------------------

test "good" (function()
  local checker = make_checker()

  print("checker", checker)

  ensure_equals("empty is good", checker:good(), true)
  ensure_equals("good have no messages", checker:msg(), "")
  ensure_tequals("good result is true", { checker:result() }, { true })
end)

test "ensure-passes" (function()
  local checker = make_checker()

  ensure_tequals(
      "ensure returns arguments",
      { checker:ensure("my message", 42, nil, 24) },
      { 42, nil, 24 }
    )

  ensure_equals("still is good", checker:good(), true)
  ensure_equals("still have no messages", checker:msg(), "")
  ensure_tequals("result is still true", { checker:result() }, { true })
end)

test "fail" (function()
  local checker = make_checker()

  ensure_equals("empty is good", checker:good(), true)

  checker:fail("my message 1")

  ensure_equals("1: fail is bad", checker:good(), false)
  ensure_equals("1: fail message default", checker:msg(), "\nmy message 1")
  ensure_equals("1: fail message custom", checker:msg("p:", ":s"), "p:my message 1")
  ensure_tequals("1: fail result default", { checker:result() }, { false, "\nmy message 1" })
  ensure_tequals("1: fail result custom", { checker:result("p:", ":s") }, { false, "p:my message 1" })

  checker:fail("my message 2")

  ensure_equals("2: fail is bad", checker:good(), false)
  ensure_equals("2: fail message default", checker:msg(), "\nmy message 1\nmy message 2")
  ensure_equals("2: fail message custom", checker:msg("p:", ":s"), "p:my message 1:smy message 2")
  ensure_tequals("2: fail result default", { checker:result() }, { false, "\nmy message 1\nmy message 2" })
  ensure_tequals("2: fail result custom", { checker:result("p:", ":s") }, { false, "p:my message 1:smy message 2" })
end)

test "ensure-fails" (function()
  local checker = make_checker()

  ensure_equals("empty is good", checker:good(), true)

  ensure_tequals(
      "failed ensure still returns arguments with false",
      { checker:ensure("my message 1", false, 42) },
      { false, 42 }
    )

  ensure_equals("1: is bad", checker:good(), false)
  ensure_equals("1: message default", checker:msg(), "\nmy message 1: 42")
  ensure_equals("1: message custom", checker:msg("p:", ":s"), "p:my message 1: 42")
  ensure_tequals("1: result default", { checker:result() }, { false, "\nmy message 1: 42" })
  ensure_tequals("1: result custom", { checker:result("p:", ":s") }, { false, "p:my message 1: 42" })

  ensure_tequals(
      "failed ensure still returns arguments with nil",
      { checker:ensure("my message 2", nil, nil, 42) },
      { nil, nil, 42 }
    )

  ensure_equals("2: is bad", checker:good(), false)
  ensure_equals("2: message default", checker:msg(), "\nmy message 1: 42\nmy message 2: nil")
  ensure_equals("2: message custom", checker:msg("p:", ":s"), "p:my message 1: 42:smy message 2: nil")
  ensure_tequals("2: result default", { checker:result() }, { false, "\nmy message 1: 42\nmy message 2: nil" })
  ensure_tequals("2: result custom", { checker:result("p:", ":s") }, { false, "p:my message 1: 42:smy message 2: nil" })
end)

--------------------------------------------------------------------------------

assert(test:run())
