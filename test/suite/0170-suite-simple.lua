--------------------------------------------------------------------------------
-- 0170-suite-simple.lua: a simple test suite test
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
-- test, case, run
do
  suite_tests_results =
  {
    to_call =
    {
      ["1"] = true,
      ["2"] = true,
      ["3"] = true
    },
    next_i = 1
  }
  local nok, errs = run_tests(
      { "test/data/suite/simple-test-1.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(suite_tests_results.to_call['1'] == nil, "to_call['1'] must be nil")
  assert(suite_tests_results.next_i == 2, "next_i must equals 2")
end

do
  suite_tests_results =
  {
    to_call =
    {
      ["1"] = true,
      ["2"] = true,
      ["3"] = true
    },
    next_i = 1
  }
  local nok, errs = run_tests(
      { "test/data/suite/simple-test-2.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `simple%-test%-2' failed:\n"
       .. " %* Test `2':(.-) this error is expected\n"
        ) ~= nil,
      "expected fail message must match"
    )
  assert(suite_tests_results.next_i == true, "next_i must be true")
  assert(next(suite_tests_results.to_call) == nil, "to_call must be empty")
end

-- run_tests, fail_on_first_error
do
  local names =
  {
    "test/data/suite/expected-error-suite.lua",
    "test/data/suite/no-error-suite.lua"
  }

  local parameters_list = {}
  parameters_list.seed_value = 123456

  --missing fail_on_first_error, default is false
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 1)

  parameters_list.fail_on_first_error = true
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 0)

  parameters_list.fail_on_first_error = false
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 1)
end

print("------> Simple suite tests suite PASSED")
