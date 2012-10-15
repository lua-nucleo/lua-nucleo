--------------------------------------------------------------------------------
-- 0051-pcall.lua: tests for pcall-part of coroutine module extensions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Test pcall indeed caches functions with weak keys -- that they are
--       collected properly.

-- TODO: Benchmark coroutine.pcall against regular pcall.

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local select, assert, type, tostring = select, assert, type, tostring
local table_concat = table.concat
local coroutine_create, coroutine_yield, coroutine_status, coroutine_resume =
      coroutine.create, coroutine.yield, coroutine.status, coroutine.resume

local ensure,
      ensure_equals,
      ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals'
      }

local make_concatter = import 'lua-nucleo/string.lua' { 'make_concatter' }

local eat_true = import 'lua-nucleo/args.lua' { 'eat_true' }

local coro = import 'lua-nucleo/coro.lua' ()
local coro_pcall = import 'lua-nucleo/pcall.lua'()

--------------------------------------------------------------------------------

local eat_tag = function(v, ...)
  if not coro.is_outer_yield_tag(v) then
    error("can't eat outer yield tag, it is: "..tostring(v), 2)
  end
  return ...
end

local eat_true_tag = function(...)
  return eat_tag(eat_true(...))
end

--------------------------------------------------------------------------------

local test = make_suite("pcall", coro_pcall)

--------------------------------------------------------------------------------

-- NOTE: Tests below check all these functions in conjunction,
--       so we're simply declaring them here as tested.
--       When adding function to this list, make sure it has tests first.

test:tests_for 'pcall'

--------------------------------------------------------------------------------

test "pcall-error-handling" (function()
  local pcall = coro_pcall.pcall

  local status, err = pcall(function() error("BOO!") end)
  ensure_equals("status check", status, false)
  assert(err:find("BOO!"), "message check")
end)

--------------------------------------------------------------------------------

test "pcall-no-error-no-yield" (function()
  local pcall = coro_pcall.pcall

  local status, C, D = pcall(
      function(A, B)
        assert(A == "A")
        assert(B == "B")
        return "C", "D"
      end,
      "A", "B"
    )

  assert(status == true)
  assert(C == "C")
  assert(D == "D")
end)

--------------------------------------------------------------------------------

test "yield_outer-across-pcall" (function()
  local pcall = coro_pcall.pcall

  local outer = coroutine_create(function(A)
    ensure_equals("A", A, "A")

    local inner = coroutine_create(function(B)
      ensure_equals("B", B, "B")

      ensure_equals(
          "F",
          eat_true(
              pcall(function(C)
                ensure_equals("C", C, "C")

                ensure_equals("E", coro.yield_outer("D"), "E")

                return "F"
              end, "C")
            ), "F"
        )

      return "G"
    end)

    ensure_equals("G", eat_true(coro.resume_inner(inner, "B")), "G")
    ensure_equals("inner dead", coroutine_status(inner), "dead")

    return "H"
  end)

  ensure_equals("H", eat_true_tag(coroutine_resume(outer, "A")), "D")
  ensure_equals("H", eat_true(coroutine_resume(outer, "E")), "H")
  ensure_equals("outer dead", coroutine_status(outer), "dead")

end)
