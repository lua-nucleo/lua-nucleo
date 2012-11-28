--------------------------------------------------------------------------------
-- 0171-suite-full.lua: set of tests for suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

dofile('test/test-lib/init/no-suite.lua')

local run_tests,
      make_suite
      = import 'lua-nucleo/suite.lua'
      {
        'run_tests',
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

local ensure_equals,
      ensure_error,
      ensure_error_with_substring,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure_error',
        'ensure_error_with_substring',
        'ensure_fails_with_substring'
      }

--------------------------------------------------------------------------------
-- asserts
do
  local test_self_and_name = function(name, fn, self, msg)
    print(name)
    ensure_fails_with_substring(
        name .. ": bad self (string)",
        function() fn("") end,
        "bad self"
      )
    msg = msg or "bad import name"
    if msg ~= 0 then
      ensure_fails_with_substring(
          name .. ": " .. msg .. " (number)",
          function() fn(self, 0) end,
          msg
        )
    end
  end

  print("\nAsserts:")
  local test = make_suite("test_empty", { name1 = true })
  test_self_and_name("test.tests_for", test.tests_for, test)
  test_self_and_name("test.TODO", test.TODO, test, "bad msg")
  test_self_and_name("test.UNTESTED", test.UNTESTED, test)
  test_self_and_name("test.set_up", test.set_up, test, 0)
  ensure_fails_with_substring(
      "test.set_up: bad function (table)",
      function() test:set_up()({ }) end,
      "bad function"
    )
  test_self_and_name("test.tear_down", test.tear_down, test, 0)
  ensure_fails_with_substring(
      "test.tear_down: bad function (table)",
      function() test:tear_down()({ }) end,
      "bad function"
    )
  test_self_and_name("test.test_for", test.test_for, test)
  test_self_and_name("test.test", test.test, test)
  ensure_fails_with_substring(
      "test.test: bad callback (table)",
      function() test:test "name" ({ }) end,
      "bad callback"
    )
  test_self_and_name("test.factory", test.factory, test)
  ensure_fails_with_substring(
      "test.factory: bad method list (number)",
      function() test:factory "name1" (0)  end,
      "expected function or table"
    )
  test_self_and_name("test.method", test.method, test)
  test_self_and_name("test.methods", test.methods, test)
  test_self_and_name(
      "test.set_fail_on_first_error",
      test.set_fail_on_first_error,
      test,
      "bad flag"
    )
  test_self_and_name(
      "test_self_and_name",
      test.set_fail_on_first_error,
      test,
      "bad flag"
    )

  -- make_suite
  ensure_fails_with_substring(
      "make_suite: bad name (number)",
      function() make_suite(0) end,
      "bad name"
    )
  ensure_fails_with_substring(
      "make_suite: bad imports (number)",
      function() make_suite("suite_name", 0) end,
      "bad imports"
    )
  ensure_fails_with_substring(
      "make_suite: bad imports value (number)",
      function() make_suite("suite_name", { 1 }) end,
      "string imports"
    )
end

--------------------------------------------------------------------------------
-- common parameters list

local parameters_list = {}
parameters_list.seed_value = 123456

--------------------------------------------------------------------------------
-- empty suite
do
  print("\nEmpty suite:")
  local nok, errs = run_tests(
      { "test/data/suite/empty-suite-error-suite.lua" },
      parameters_list
    )
  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `empty-suite-error-suite' failed:\n"
                  .. " * Test `[completeness check]': empty\n",
      "expected fail message must match"
    )
end

--------------------------------------------------------------------------------
-- TODO: don't use global variables in suite tests
-- https://github.com/lua-nucleo/lua-nucleo/issues/5

assert(
  not is_declared("suite_tests_results"),
  "global suite_tests_results variable already declared"
)
declare("suite_tests_results")

--------------------------------------------------------------------------------
-- simple suite tests
do
  print("\nSingle test suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-test-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle case suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-case-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle test_for suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-test_for-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle tests_for suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-tests_for-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle tests_for error:")

  local nok, errs = run_tests(
      { "test/data/suite/single-tests_for-error.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find("suite: unknown import `to_test'", 1, true) ~= nil,
      "expected fail message must match"
    )
end

do
  print("\nSingle group suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-group-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSet_strict_mode false suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/set_strict_mode-false-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSet_strict_mode true suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/set_strict_mode-true-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `set_strict_mode-true-suite' failed:\n"
                  .. " * Test `[STRICT MODE]': detected TODOs:\n"
                  .. "   -- write tests for `to_test'\n"
                  .. "\n",
      "expected fail message must match"
    )
end

do
  print("\nSingle set_fail_on_first_error false suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-set_fail_on_first_error-false-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 tests must be fail")
  assert(
      errs[1].err ==
              "Suite `single-set_fail_on_first_error-false-suite' failed:\n"
           .. " * Test `fail_one': any error\n"
           .. " * Test `fail_two': any error\n",
      "expected fail message must match"
    )
  assert(
      suite_tests_results == 11,
      "suite_tests_results must be set to 11"
    )
end

do
  print("\nSingle set_fail_on_first_error true suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-set_fail_on_first_error-true-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 tests must be fail")
  assert(
      errs[1].err ==
              "Suite `single-set_fail_on_first_error-true-suite' failed:\n"
           .. " * Test `fail_one': any error\n"
           .. " * Test `[FAIL ON FIRST ERROR]': FAILED AS REQUESTED\n",
      "expected fail message must match"
    )
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle UNTESTED unstrict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-UNTESTED-unstrict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

do
  print("\nSingle UNTESTED strict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-UNTESTED-strict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err ==
              "Suite `single-UNTESTED-strict-mode-suite' failed:\n"
           .. " * Test `[STRICT MODE]': detected TODOs:\n"
           .. "   -- write tests for `to_test'\n"
           .. "\n",
      "expected fail message must match"
    )
end

do
  print("\nSingle BROKEN unstrict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-BROKEN-unstrict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

do
  print("\nSingle BROKEN strict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-BROKEN-strict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err ==
              "Suite `single-BROKEN-strict-mode-suite' failed:\n"
           .. " * Test `[STRICT MODE]': detected TODOs:\n"
           .. "   -- BROKEN TEST: to_test\n"
           .. "\n",
      "expected fail message must match"
    )
end

do
  print("\nSingle BROKEN with decorator suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-BROKEN-with-decorator-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must successfull")
  assert(#errs == 0, "0 test must fail")
end

do
  print("\nSingle TODO unstrict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-TODO-unstrict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

do
  print("\nSingle TODO strict mode suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-TODO-strict-mode-suite.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err ==
              "Suite `single-TODO-strict-mode-suite' failed:\n"
           .. " * Test `[STRICT MODE]': detected TODOs:\n"
           .. "   -- to_test\n"
           .. "\n",
      "expected fail message must match"
    )
end

do
  print("\nSingle factory suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-factory-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

do
  print("\nSingle method suite:")

  suite_tests_results = 0
  local nok, errs = run_tests(
      { "test/data/suite/single-method-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
  assert(
      suite_tests_results == 1,
      "suite_tests_results must be set to 1"
    )
end

do
  print("\nSingle methods suite:")

  local nok, errs = run_tests(
      { "test/data/suite/single-methods-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

do
  print("\nRandomseed value test:")

  suite_tests_results =
  {
    value = nil,
    other_value = nil
  }
  local nok, errs = run_tests(
      { "test/data/suite/randomseed-value-test.lua" },
      { seed_value = 12345 }
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")

  math.randomseed(12345)
  assert(suite_tests_results.value == math.random(), "random values equal")

  -- math.randomseed(12345)
  -- ensure_equals("test:run()", other_value == math.random(), true)
  -- TODO: we get one randomseed for suite, not for case

  math.randomseed(12346)
  assert(suite_tests_results.value ~= math.random(), "random values not equal")
end

do
  print("\nSet_up and tear_down test:")

  suite_tests_results =
  {
    value = nil,
    other_value = nil,
    counter = 0
  }
  local nok, errs = run_tests(
      { "test/data/suite/set_up-and-tear_down-test.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")

  assert(
      suite_tests_results.counter == 2,
      "tear_down results: counter must be equals 2"
    )
  math.randomseed(12345)
  assert(
      suite_tests_results.value == math.random(),
      "random values equal"
    )
  math.randomseed(12345)
  assert(
      suite_tests_results.other_value == math.random(),
      "random values equal"
    )
  math.randomseed(12346)
  assert(
      suite_tests_results.value ~= math.random(),
      "random values not equal"
    )
end

do
  print("\nSet_up duplication test:")

  local nok, errs = run_tests(
      { "test/data/suite/set_up-duplication-test.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find("set_up duplication", 1, true) ~= nil,
      "expected fail message must match"
    )
end

do
  print("\nTear_down duplication test:")

  local nok, errs = run_tests(
      { "test/data/suite/tear_down-duplication-test.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find("tear_down duplication", 1, true) ~= nil,
      "expected fail message must match"
    )
end

do
  print("\nSet_up test fail:")

  local nok, errs = run_tests(
      { "test/data/suite/set_up-test-fail.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `set_up%-test%-fail' failed:\n"
       .. " %* Test `any':(.-) expected error\n"
        ) ~= nil,
      "expected fail message must match"
    )
end

do
  print("\nTear_down test fail:")

  local nok, errs = run_tests(
      { "test/data/suite/tear_down-test-fail.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `tear_down%-test%-fail' failed:\n"
       .. " %* Test `any':(.-) expected error\n"
        ) ~= nil,
      "expected fail message must match"
    )
end

--------------------------------------------------------------------------------
-- test:with decorators
do
  print("\nTesting test decorators:")

  local nok, errs = run_tests(
      { "test/data/suite/decorators-suite.lua" },
      parameters_list
    )

  assert(nok == 1, "1 tests must be successfull")
  assert(#errs == 0, "0 test must be fail")
end

--------------------------------------------------------------------------------
-- test:factory table input test
do
  print("\nComplex factory table input test 1:")

  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-table-input-test-1.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-table-input-test-1' failed:\n"
                  .. " * Test `[completeness check]':"
                  .. " detected untested imports:"
                  .. " some_factory:method3, some_factory:method1,"
                  .. " other_factory, some_factory:method2\n",
      "expected fail message must match"
    )
end

do
  print("\nComplex factory table input test 2:")

  suite_tests_results = 1
  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-table-input-test-2.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-table-input-test-2' failed:\n"
                  .. " * Test `[completeness check]':"
                  .. " detected untested imports:"
                  .. " some_factory:method3,"
                  .. " other_factory, some_factory:method2\n",
      "expected fail message must match"
    )
  assert(
      suite_tests_results == 2,
      "suite_tests_results must be set to 2"
    )
end

do
  print("\nComplex factory table input test 3:")

  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-table-input-test-3.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-table-input-test-3' failed:\n"
                  .. " * Test `[completeness check]':"
                  .. " detected untested imports:"
                  .. " other_factory\n",
      "expected fail message must match"
    )
end

--------------------------------------------------------------------------------
-- test:factory function input test
do
  print("\nComplex factory function input test 1:")

  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-function-input-test-1.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-function-input-test-1' failed:\n"
                  .. " * Test `[completeness check]': empty\n",
      "expected fail message must match"
    )
end

do
  print("\nComplex factory function input test 2:")

  suite_tests_results = 1
  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-function-input-test-2.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-function-input-test-2' failed:\n"
                  .. " * Test `[completeness check]':"
                  .. " detected untested imports:"
                  .. " make_some, make_another:method2,"
                  .. " make_another:method3\n",
      "expected fail message must match"
    )
  assert(
      suite_tests_results == 3,
      "suite_tests_results must be set to 3"
    )
end

do
  print("\nComplex factory function input test 3:")

  local nok, errs = run_tests(
      { "test/data/suite/complex-factory-function-input-test-3.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err == "Suite `complex-factory-function-input-test-3' failed:\n"
                  .. " * Test `[completeness check]':"
                  .. " detected untested imports:"
                  .. " make_some\n",
      "expected fail message must match"
    )
end

--------------------------------------------------------------------------------
-- Complex test
do
  print("\nComplex test 1:")

  suite_tests_results = 1
  local nok, errs = run_tests(
      { "test/data/suite/complex-test-1.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `complex%-test%-1' failed:\n"
       .. " %* Test `func2_two': (.-): Expected error."
        ) ~= nil,
      "expected fail message must match"
    )
  assert(suite_tests_results == 2 * 3 * 7 * 11, "product")
end

do
  print("\nComplex test 2:")

  suite_tests_results = 1
  local nok, errs = run_tests(
      { "test/data/suite/complex-test-2.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `complex%-test%-2' failed:\n"
       .. " %* Test `func2_two': (.-): Expected error.\n"
       .. " %* Test `%[STRICT MODE%]': detected TODOs:\n"
       .. "   %-%- write tests for `func3'\n"
       .. "   %-%- TODOs can duplicate func names\n"
       .. "   %-%- func4"
        ) ~= nil,
      "expected fail message must match"
    )
  assert(suite_tests_results == 2 * 3 * 5 * 7 * 11, "product")
end

do
  print("\nComplex test 3:")

  suite_tests_results = 1
  local nok, errs = run_tests(
      { "test/data/suite/complex-test-3.lua" },
      parameters_list
    )

  assert(nok == 0, "0 tests must be successfull")
  assert(#errs == 1, "1 test must be fail")
  assert(
      errs[1].err:find(
          "Suite `complex%-test%-3' failed:\n"
       .. " %* Test `func2_two': (.-): Expected error.\n"
       .. " %* Test `%[FAIL ON FIRST ERROR%]': FAILED AS REQUESTED\n"
        ) ~= nil,
      "expected fail message must match"
    )
  assert(suite_tests_results == 2 * 3 * 5 * 7, "product")
end

print("------> Full suite tests suite PASSED")
