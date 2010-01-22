-- suite-full.lua: set of tests for suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

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
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals',
        'ensure_error',
        'ensure_fails_with_substring'
      }

--------------------------------------------------------------------------------
-- asserts
do
  print("\nAsserts:")
  local test = make_suite("test_empty", { name1 = true })

  -- tests_for
  ensure_fails_with_substring(
      "test.tests_for('')",
      function() test.tests_for("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.tests_for, test, 0",
      function() test:tests_for(0) end,
      "bad import name"
    )

  -- TODO
  ensure_fails_with_substring(
      "test.TODO('')",
      function() test.TODO("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.TODO, test, 0",
      function() test:TODO(0) end,
      "bad msg"
    )

  -- UNTESTED
  ensure_fails_with_substring(
      "test.UNTESTED('')",
      function()  test.UNTESTED("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.UNTESTED, test, 0",
      function() test:UNTESTED(0)  end,
      "bad import name"
    )

  -- test_for
  ensure_fails_with_substring(
      "test.test_for('')",
      function() test.test_for("") end,
      "bad self"
    )

   ensure_fails_with_substring(
      "test.test_for, test, 0",
      function() test:test_for(0) end,
      "bad import name"
    )

  -- test
  ensure_fails_with_substring(
      "test.test('')",
      function() test.test("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test:test(0)",
      function() test:test(0) end,
      "bad import name"
    )

  ensure_fails_with_substring(
      "test.test(test, 'name'), { }",
      function() test:test "name" ({ }) end,
      "bad callback"
    )

  -- factory
  ensure_fails_with_substring(
      "test.factory('')",
      function() test.factory("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.factory, test, 0",
      function() test:factory(0) end,
      "bad import name"
    )


  ensure_fails_with_substring(
      "test.factory(test, 'name'), 0",
      function() test:factory "name1" (0)  end,
      "expected function or table"
    )

  -- method
  ensure_fails_with_substring(
      "test.method('')",
      function() test.method("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.method, test, 0",
      function() test:method(0) end,
      "bad import name"
    )

  -- methods
  ensure_fails_with_substring(
      "test.methods('')",
      function() test.methods("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.methods, test, 0",
      function() test:methods(0) end,
      "bad import name"
    )

  -- run
  ensure_fails_with_substring(
      "test.run('')",
      function() test.run("") end,
      "bad self"
    )

  -- set_strict_mode
  ensure_fails_with_substring(
      "test.set_strict_mode('')",
      function() test.set_strict_mode("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.set_strict_mode, test, 0",
      function() test:set_strict_mode(0) end,
      "bad flag"
    )

  -- set_fail_on_first_error
  ensure_fails_with_substring(
      "test.set_fail_on_first_error('')",
      function() test.set_fail_on_first_error("") end,
      "bad self"
    )

  ensure_fails_with_substring(
      "test.set_fail_on_first_error, test, 0",
      function() test:set_fail_on_first_error(0) end,
      "bad flag"
    )

  -- make_suite
  ensure_fails_with_substring(
      "make_suite, 0",
      function() make_suite(0) end,
      "bad name"
    )

  ensure_fails_with_substring(
      "test.set_fail_on_first_error, test, 0",
      function() make_suite("suite_name", 0) end,
      "bad imports"
    )

  ensure_fails_with_substring(
      "test.set_fail_on_first_error, test, 0",
      function() make_suite("suite_name", { 1 }) end,
      "string imports"
    )
end

--------------------------------------------------------------------------------
-- empty suite
do
  print("\nEmpty suite:")
  local test = make_suite("test_empty", { })
  ensure_error(
      "test:run()",
      "Suite `test_empty' failed:\n"
   .. " * Test `[completeness check]': empty\n",
      test:run()
    )
end

--------------------------------------------------------------------------------
-- simple suite tests
do
  print("\nSingle test suite:")
  local test = make_suite("test", { })
  local counter = 0
  test "test_1" (function()
    counter = 1
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSingle case suite:")
  local test = make_suite("test", { })
  local counter = 0
  test:case "test_1" (function()
    counter = 1
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSingle test_for suite:")
  local test = make_suite("test", { to_test = true })
  local counter = 0
  test:test_for "to_test" (function()
    counter = counter + 1
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSingle tests_for suite:")
  local test = make_suite("test", { to_test = true })
  local counter = 0
  test:tests_for "to_test"
  test "any" (function()
    counter = counter + 1
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSingle tests_for error:")
  local test = make_suite("test", { })
  ensure_fails_with_substring(
      "test.tests_for('')",
      function() test:tests_for("to_test") end,
      "unknown import"
    )
end

do
  print("\nSingle group suite:")
  local test = make_suite("test", { to_test = true })
  local counter = 0
  test:group "to_test"
  test "any" (function()
    counter = counter + 1
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSet_strict_mode suite:")
  local test = make_suite("test", { to_test = true })
  local counter = 0
  test:UNTESTED "to_test"
  test "any" (function()
    counter = counter + 1
    if test:in_strict_mode() then
      counter = counter + 1
    end
  end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
  ensure_equals("strict_mode", test.strict_mode_, false)
  test:set_strict_mode(true)
  ensure_equals("strict_mode", test.strict_mode_, true)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[STRICT MODE]': detected TODOs:\n"
   .. "   -- write tests for `to_test'\n\n",
      test:run()
    )
  ensure_equals("Sum", counter, 3)
end

do
  print("\nSingle set_fail_on_first_error suite:")
  local test = make_suite("test", { })
  local counter = 0
  test "fail_one" (function()
    counter = counter + 1
    error("any error", 0)
  end)
  test "fail_two" (function()
    counter = counter + 10
    error("any error", 0)
  end)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `fail_one': any error\n"
   .. " * Test `fail_two': any error\n",
      test:run()
    )
  ensure_equals("Sum", counter, 11)
  ensure_equals("fail_on_first_error", test.fail_on_first_error_, false)
  test:set_fail_on_first_error(true)
  ensure_equals("fail_on_first_error", test.fail_on_first_error_, true)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `fail_one': any error\n"
   .. " * Test `[FAIL ON FIRST ERROR]': FAILED AS REQUESTED\n",
      test:run()
    )
  ensure_equals("Sum", counter, 12)
end

do
  print("\nSingle UNTESTED suite:")
  local test = make_suite("test", { to_test = true })
  test:UNTESTED "to_test"
  ensure_equals("test:run()", test:run(), true)
end

do
  print("\nSingle TODO suite:")
  local test = make_suite("test", { })
  test:TODO "to_test"
  ensure_equals("test:run()", test:run(), true)
end

do
  print("\nSingle factory suite:")
  local test = make_suite("test", { to_test = true })
  test:factory "to_test" { }
  test "any" (function() end)
  ensure_equals("test:run()", test:run(), true)
end

do
  print("\nSingle method suite:")
  local test = make_suite("test", { to_test = true })
  local counter = 0
  test:factory "to_test" { "method" }
  test:method "method" (function() counter = 1 end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSingle methods suite:")
  local test = make_suite("test", { to_test = true })
  test:factory "to_test" { "method1", "method2" }
  test:methods "method1" "method2"
  test "any" (function() end)
  ensure_equals("test:run()", test:run(), true)
end

--------------------------------------------------------------------------------
-- test:factory table input test
do
  print("\nComplex factory table input test:")
  local test = make_suite(
      "test",
      {
        some_factory = true,
        other_factory = true
      }
    )
  local var = 1

  test:factory "some_factory" { "method0", "method1", "method2", "method3" }
  test:method "method0" (function() end)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': detected untested imports:"
   .. " some_factory:method3, some_factory:method1,"
   .. " other_factory, some_factory:method2\n",
      test:run()
    )

  test:method "method1" (function() var = 2 end)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': detected untested imports:"
   .. " some_factory:method3,"
   .. " other_factory, some_factory:method2\n",
      test:run()
    )
  ensure_equals("var == 2", var, 2)

  test:methods "method2" "method3"
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': detected untested imports:"
   .. " other_factory\n",
      test:run()
    )

  test:factory "other_factory" { }
  ensure_equals("test:run()", test:run(), true)
end

--------------------------------------------------------------------------------
-- test:factory function input test
do
  print("\nComplex factory function input test:")
  local make_some = function()
    return
    {
      method1 = 5,
      method2 = "",
      method3 = {}
    }
  end

  local make_another = function(a, b, c)
    assert_is_number(a)
    assert_is_string(b)
    assert_is_table(c)
    local method1 = function() end
    local method2 = function() end
    local method3 = function() end
    return
    {
      method1 = method1,
      method2 = method2,
      method3 = method3
    }
  end

  local test = make_suite(
      "test",
      {
        make_some = true,
        make_another = true
      }
    )

  test:factory "make_another" (make_another, 1, "", {})
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': empty\n",
      test:run()
    )

  local var = 1
  test:method "method1" (function() var = var + 2 end)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': detected untested imports:"
   .. " make_some, make_another:method2,"
   .. " make_another:method3\n",
      test:run()
    )
  ensure_equals("var", var, 3)

  test:methods "method2" "method3"
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[completeness check]': detected untested imports:"
   .. " make_some\n",
      test:run()
    )

  test:factory "make_some" (make_some)
  ensure_equals("test:run()", test:run(), true)
end

--------------------------------------------------------------------------------
-- Complex test
do
  print("\nComplex test:")
  local make_another = function()
    local method1 = function() end
    local method2 = function() end
    local method3 = function() end
    return
    {
      method1 = method1,
      method2 = method2,
      method3 = method3
    }
  end

  local test = make_suite(
      "test",
      {
        make_another = true,
        func1 = true,
        func2 = true,
        func3 = true,
        func4 = true
      }
    )
  local counter = 1
  test "any" (function()
    counter = counter * 2
  end)
  test:test_for "func1" (function()
    counter = counter * 3
  end)
  test:tests_for "func2"
  test:case "func2_one" (function()
    if test:in_strict_mode() then
      counter = counter * 5
    end
  end)

  test "func2_two" (function()
    counter = counter * 7
    error("Expected error.")
  end)
  test:UNTESTED "func3"
  test:TODO "TODOs can duplicate func names"
  test:TODO "func4"
  test:test_for "func4" (function() end)

  test:factory "make_another" (make_another)
  test:method "method1" (function() counter = counter * 11 end)
  test:methods "method2" "method3"

  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `func2_two': test/suite-full.lua:548: Expected error.\n",
      test:run()
    )
  ensure_equals("product", counter, 2 * 3 * 7 * 11)

  counter = 1
  test:set_strict_mode(true)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `func2_two': test/suite-full.lua:548: Expected error.\n"
   .. " * Test `[STRICT MODE]': detected TODOs:\n"
   .. "   -- write tests for `func3'\n"
   .. "   -- TODOs can duplicate func names\n"
   .. "   -- func4\n\n",
      test:run()
    )
  ensure_equals("product", counter, 2 * 3 * 5 * 7 * 11)

  counter = 1
  test:set_fail_on_first_error(true)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `func2_two': test/suite-full.lua:548: Expected error.\n"
   .. " * Test `[FAIL ON FIRST ERROR]': FAILED AS REQUESTED\n",
      test:run()
    )
  ensure_equals("product", counter, 2 * 3 * 5 * 7)
end
