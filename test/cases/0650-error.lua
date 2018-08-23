--------------------------------------------------------------------------------
-- test/cases/0650-error.lua: tests for error.lua
-- This file is a part of Lua-Aplicado library
-- Copyright (c) Lua-Aplicado authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

local log, dbg, spam, log_error
      = import 'lua-nucleo/log.lua' { 'make_loggers' } (
         "test/error", "T650"
       )

--------------------------------------------------------------------------------

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_error,
      ensure_fails_with_substring,
      ensure_returns,
      ensure_tdeepequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_error',
        'ensure_fails_with_substring',
        'ensure_returns',
        'ensure_tdeepequals'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local pack
      = import 'lua-nucleo/args.lua'
      {
        'pack'
      }

local call,
      fail,
      try,
      rethrow,
      xfinally,
      xcall,
      create_error_object,
      is_error_object,
      error_handler_for_call,
      error_exports
      = import 'lua-nucleo/error.lua'
      {
        'call',
        'fail',
        'try',
        'rethrow',
        'xfinally',
        'xcall',
        'create_error_object',
        'is_error_object',
        'error_handler_for_call'
      }

--------------------------------------------------------------------------------

local test = make_suite("error", error_exports)
-- local test = (...)("error", error_exports)

--------------------------------------------------------------------------------

test:group "xfinally"

test:case "result-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "return value",
      1, { 42 },
      xfinally(
          function()
            return 42
          end,
          function()
            finalized = true
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "many-results-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "return multiple values",
      3, { 42, 43, 44 },
      xfinally(
          function()
            return 42, 43, 44
          end,
          function()
            finalized = true
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "error-inside-finalizer" (function(env)
  ensure_fails_with_substring(
      "should raise error",
      function()
        xfinally(
            function()
              return 42
            end,
            function()
              error("exception_to_catch")
            end
        )
      end,
      "exception_to_catch"
    )
end)

test:case "handle-error-and-finalize-after" (function(env)
  local finalized = false
  ensure_fails_with_substring(
      "should raise error",
      function()
        xfinally(
            function()
              error("exception_to_catch")
            end,
            function()
              finalized = true
            end
          )
      end,
      "exception_to_catch"
    )
  ensure("finalized", finalized)
end)

test:case "error-and-error-inside-finalizer" (function(env)
  ensure_fails_with_substring(
      "should raise error",
      function()
        xfinally(
            function()
              error("first_error")
            end,
            function()
              error("second_error")
            end
          )
      end,
      "first_error"
    )
end)

--------------------------------------------------------------------------------

test:group "xcall"

test:case "xcall-result-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "return value",
      2, { true, 42 },
      xcall(
          function()
            return 42
          end,
          function()
            finalized = true
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "xcall-many-results-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "return multiple values",
      4, { true, 42, 43, 44 },
      xcall(
          function()
            return 42, 43, 44
          end,
          function()
            finalized = true
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "xcall-error-inside-finalizer" (function(env)
  -- we can't use ensure_returns, because it can't match exception tracebacks
  local ok, err, fin_ok, fin_err = xcall(
      function()
        return 42
      end,
      function()
        error("something happens")
      end
    )
  ensure_equals("not ok", ok, nil)
  ensure_equals("err", err, nil)
  ensure_equals("finalizer failed", fin_ok, nil)
  ensure("error", fin_err)
end)

test:case "xcall-handle-error-and-finalize-after" (function(env)
  -- we can't use ensure_returns, because it can't match exception tracebacks
  local finalized = false
  local ok, err, fin_ok, fin_err = xcall(
      function()
        error("something happens")
      end,
      function()
        finalized = true
      end
    )
  ensure_equals("not ok", ok, nil)
  ensure_equals("finalized ok", fin_ok, true)
  ensure("error returned", err)
  ensure("finalized", finalized)
end)

test:case "xcall-handle-errors-in-function-and-finalizer" (function(env)
  -- we can't use ensure_returns, because it can't match exception tracebacks
  local ok, err, fin_ok, fin_err = xcall(
      function()
        error("something happens")
      end,
      function()
        error("something happens")
      end
    )
  ensure_equals("not ok", ok, nil)
  ensure_equals("finalized ok", fin_ok, nil)
  ensure("error returned", err)
  ensure("finalizer error returned", fin_err)
end)

--------------------------------------------------------------------------------

test:group "fail"

-- This test captures return stack via pack(pcall(...)), then examines it
-- to ensure correctness of returned values.
--
-- TODO: https://github.com/lua-aplicado/lua-aplicado/issues/14
--       This test should be rewritten, using ensure_returns and predicate
test:case "fail-generate-proper-error-object" (function(env)
  local num, values = pack(
        pcall(
            function()
              fail("TEST_ERROR", "test error")
            end
          )
    )
  ensure_equals("pcall return two values", num, 2)
  ensure_equals("pcall return two values", values[1], false)
  ensure("is error object", is_error_object(values[2]))
end)

test:case "fail-require-error-id" (function(env)
  ensure_fails_with_substring(
      "fail() require error_id argument",
      function()
        fail(nil, "error message")
      end,
      "argument #1: expected `string', got `nil'"
    )
end)

test:case "fail-require-error-message" (function(env)
  ensure_fails_with_substring(
      "fail() require error_message argument",
      function()
        fail("TEST_ERROR")
      end,
      "argument #2: expected `string', got `nil'"
    )
end)

--------------------------------------------------------------------------------

test:group "call"

test:case "call-function-returns-single-value" (function(env)
  ensure_returns(
      "call returns single value",
      1, { 42 },
      call(function()
        return 42
      end)
    )
end)

test:case "call-function-returns-many-values" (function(env)
  ensure_returns(
      "call returns multiple values",
      3, { 42, 43, 44 },
      call(
          function()
            return 42, 43, 44
          end
        )
    )
end)

test:case "call-and-fail" (function(env)
  ensure_returns(
      "call return proper error value",
      2,
      { nil, "TEST_ERROR" },
      call(
          function()
            fail("TEST_ERROR", "test error")
          end
        )
    )
end)

test:case "call-and-plain-error" (function(env)
  local ok, err
  ensure_fails_with_substring(
      "error pass through",
      function()
        ok, err = call(
            function()
              error("test error")
            end
          )
      end,
      "test error"
    )
  ensure_equals("nil", ok, nil)
  ensure_equals("error skipped", err, nil)
end)

--------------------------------------------------------------------------------

test:group "try"

test:case "try-ok" (function(env)
  ensure_returns(
      "try() return correct value (outer test)",
      2, { 42, "error message" },
      call(
          function()
            return ensure_returns(
                "try() return correct value (inner test)",
                2,
                { 42, "error message" },
                try("TEST_ERROR", 42, "error message")
              )
          end
        )
    )
end)

-- TODO: https://github.com/lua-aplicado/lua-aplicado/issues/15
--       Ensure that error message was logged
test:case "try-and-fail" (function(env)
  ensure_returns(
      "try fails and return proper error value",
      2, { nil, "TEST_ERROR" },
      call(
          function()
            local value = try("TEST_ERROR", nil, "error message")
            error("unreachable")
          end
        )
    )
end)

--------------------------------------------------------------------------------

test:group "rethrow"

test:case "rethrow-fail" (function(env)
  local failure_obj = create_error_object("TEST_ERROR", "test error")
  ensure_returns(
      "rethrow error object",
      2, { nil, "TEST_ERROR" },
      call(
          function()
            rethrow("NEW_ERROR", failure_obj)
          end
        )
    )
end)

test:case "rethrow-error" (function(env)
  ensure_returns(
      "rethrow plain error",
      2, { nil, "NEW_ERROR" },
      call(
          function()
            rethrow("NEW_ERROR", "plain test error")
          end
        )
    )
end)

--------------------------------------------------------------------------------

-- Test for error.lua semi-public functions
--
-- These tests are related on implementation details, and can be altered,
-- on implementation change, even if public contract stay unchanged
test:group "create_error_object"

test:case "create-error-object" (function(env)
  -- Assuming knowledge about internal layout of "error object" table,
  -- we inspect content of value
  local value = create_error_object("TEST_ERROR", "message")
  ensure("error object is table", is_table(value))
  ensure_equals("error object has proper error ID set", value[2], "TEST_ERROR")

  -- "error object" use table reference as marker, create another "error"
  -- and ensure if marker is same.
  local another_value = create_error_object("ANOTHER", "message")
  ensure_equals("markers are equal", value[1], another_value[1])
end)

test:group "is_error_object"

test:case "is-error-object-positive-test" (function(env)
  local value = create_error_object("TEST_ERROR", "message")
  ensure_returns(
      "is_error_object() recognizes error object",
      1, { true },
      is_error_object(value)
    )
end)

test:case "is-error-object-negative-test" (function(env)
  ensure_returns(
      "is_error_object() does not recognize number as error object",
      1, { false },
      is_error_object(42)
    )
  ensure_returns(
      "is_error_object() does not recognize string as error object",
      1, { false },
      is_error_object("fourty two")
    )
  ensure_returns(
      "is_error_object() does not recognize table as error object",
      1, { false },
      is_error_object( { 42 } )
    )
  ensure_returns(
      "is_error_object() does not recognize boolean (true) as error object",
      1, { false },
      is_error_object(true)
    )
  ensure_returns(
      "is_error_object() does not recognize boolean (false) as error object",
      1, { false },
      is_error_object(false)
    )
  ensure_returns(
      "is_error_object() does not recognize nil as error object",
      1, { false },
      is_error_object(nil)
    )
end)

-- TODO: https://github.com/lua-aplicado/lua-aplicado/issues/16
test:UNTESTED "error_handler_for_call"

--------------------------------------------------------------------------------

-- Test xfinally transparency for call/fail

test:case "call-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "call returns value",
      1, { 42 },
      call(
          function()
            return xfinally(
                function()
                  return 42
                end,
                function()
                  finalized = true
                end
              )
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "call-function-many-results-and-finalize" (function(env)
  local finalized = false
  ensure_returns(
      "call returns multiple values",
      3, { 42, 43, 44 },
      call(
          function()
            return xfinally(
                function()
                  return 42, 43, 44
                end,
                function()
                  finalized = true
                end
              )
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "call-and-fail-inside-finalizer" (function(env)
  ensure_returns(
      "return proper error when finalizer fails",
      2, { nil, "TEST_ERROR" },
      call(
          function()
            xfinally(
                function()
                  return 42
                end,
                function()
                  fail("TEST_ERROR", "test error")
                end
              )
          end
        )
    )
end)

test:case "handle-fail-and-finalize-after" (function(env)
  local finalized = false
  ensure_returns(
      "xfinally is transparent for exception raised by fail",
      2, { nil, "TEST_ERROR" },
      call(
          function()
            xfinally(
                function()
                  fail("TEST_ERROR", "test error")
                end,
                function()
                  finalized = true
                end
              )
          end
        )
    )
  ensure("finalized", finalized)
end)

test:case "fail-and-fail-inside-finalizer" (function(env)
  ensure_returns(
      "fail and fail inside finalizer",
      2, { nil, "TEST_ERROR"},
      call(
          function()
            xfinally(
                function()
                  fail("TEST_ERROR", "first_error")
                end,
                function()
                  fail("TEST_HANDLER_ERROR", "second_error")
                end
              )
          end
        )
    )
end)
