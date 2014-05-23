--------------------------------------------------------------------------------
-- 0173-filter-test-names.lua: test whether tests are selectable by name
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
      { "test/data/suite/filter-test-names.lua" },
      { seed_value = 123456 }
    )
  assert(nok == 1, "1 suite ok")
  assert(#errs == 0, "0 tests failed")
  assert(suite_tests_results.counter == 111, "all tests have run")
end

do
  suite_tests_results = {counter = 0}
  local nok, errs = run_tests(
      { "test/data/suite/filter-test-names.lua" },
      { seed_value = 123456, names = { "100", "1" } }
    )
  assert(nok == 1, "1 suite ok")
  assert(#errs == 0, "0 tests failed")
  assert(suite_tests_results.counter == 101, "100 and 1 have run")
end

do
  suite_tests_results = {counter = 0}
  local nok, errs = run_tests(
      { "test/data/suite/filter-test-names.lua" },
      { seed_value = 123456, names = { "200", "20", "10" } }
    )
  assert(nok == 1, "1 suite ok")
  assert(#errs == 0, "0 tests failed")
  assert(suite_tests_results.counter == 10, "only 10 has run")
end

print("------> Select tests by name suite PASSED")
