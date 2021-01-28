--------------------------------------------------------------------------------
-- 0171-suite-BLOCKED_IF.lua: set of tests for suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

dofile('test/test-lib/init/no-suite.lua')

local run_tests,
      run_test,
      make_suite
      = import 'lua-nucleo/suite.lua'
      {
        'run_tests',
        'run_test',
        'make_suite'
      }

local assert_is_number,
      assert_is_string,
      assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_string',
        'assert_is_table'
      }

local ensure,
      ensure_equals,
      ensure_returns,
      ensure_error,
      ensure_error_with_substring,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_returns',
        'ensure_error',
        'ensure_error_with_substring',
        'ensure_fails_with_substring'
      }

--------------------------------------------------------------------------------
-- common parameters list

local parameters_list = {}
parameters_list.seed_value = 123456

--------------------------------------------------------------------------------
-- TODO: don't use global variables in suite tests
-- https://github.com/lua-nucleo/lua-nucleo/issues/5

assert(
  not is_declared("suite_tests_results"),
  "global suite_tests_results variable already declared"
)
declare("suite_tests_results")

--------------------------------------------------------------------------------

do
  print("\nSingle BROKEN_IF strict mode suite (broken):")

  suite_tests_results = 0
  local nok, errs = run_tests(
    { "test/data/suite/single-BROKEN-IF-broken-strict-mode-suite.lua" },
    parameters_list
  )

  assert(suite_tests_results == 0, "0 tests results must be collected, actual: " .. tostring(suite_tests_results))
  assert(nok == 0, "0 tests must be successful, actual: " .. tostring(nok))
  assert(#errs == 1, "1 test must fail, actual: " .. tostring(#errs))

  assert(
    errs[1].err ==
      "Suite `single-BROKEN-IF-broken-strict-mode-suite' failed:\n"
        .. " * Test `[STRICT MODE]': detected TODOs:\n"
        .. "   -- BROKEN TEST: intentionally_broken_test1: conditionally broken\n"
        .. "   -- BROKEN TEST: intentionally_broken_test2: conditionally broken\n"
        .. "   -- BROKEN TEST: intentionally_broken_test3: conditionally broken\n"
        .. "\n",
    "expected fail message must match"
  )
end

--do
--  print("\nSingle BROKEN_IF strict mode suite (non-broken):")
--
--  local nok, errs = run_tests(
--    { "test/data/suite/single-BROKEN-IF-non-broken-strict-mode-suite.lua" },
--    parameters_list
--  )
--
--  assert(nok == 1, "1 tests must be successful")
--  assert(#errs == 0, "0 test must fail")
--end
--
--do
--  print("\nSingle BROKEN_IF unstrict mode suite (broken):")
--
--  local nok, errs = run_tests(
--    { "test/data/suite/single-BROKEN-IF-broken-unstrict-mode-suite.lua" },
--    parameters_list
--  )
--
--  assert(nok == 1, "1 tests must be successful")
--  assert(#errs == 0, "0 test must fail")
--end
--
--do
--  print("\nSingle BROKEN_IF unstrict mode suite (non-broken):")
--
--  local nok, errs = run_tests(
--    { "test/data/suite/single-BROKEN-IF-non-broken-unstrict-mode-suite.lua" },
--    parameters_list
--  )
--
--  assert(nok == 1, "1 tests must be successful")
--  assert(#errs == 0, "0 test must fail")
--end

print("------> BROKEN_IF suite tests suite PASSED")
