--------------------------------------------------------------------------------
-- 0172-suite-skip-slow.lua: test whether slow tests are skippable
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Test run_tests
-- TODO: Test make_suite with imports_list argument and related methods.
-- TODO: Test strict mode

dofile('test/test-lib/init/no-suite.lua')

local run_tests,
      make_suite
      = import 'lua-nucleo/suite.lua'
      {
        'run_tests',
        'make_suite'
      }

assert(pcall(function() make_suite() end) == false)

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
  suite_tests_results = {counter = 0}
  local nok, errs = run_tests(
      { "test/data/suite/skip-slow-test.lua" },
      { seed_value = 123456 }
    )
  assert(nok == 1, "1 suite ok")
  assert(#errs == 0, "0 tests failed")
  assert(suite_tests_results.counter == 3, "both tests has run")
end

do
  suite_tests_results = {counter = 0}
  local nok, errs = run_tests(
      { "test/data/suite/skip-slow-test.lua" },
      { seed_value = 123456, quick = true }
    )
  assert(nok == 1, "1 suite ok")
  assert(#errs == 0, "0 tests failed")
  assert(suite_tests_results.counter == 1, "only quick test has run")
end

print("------> Skip slow tests suite PASSED")
