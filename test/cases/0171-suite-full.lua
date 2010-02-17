-- suite-full.lua: set of tests for suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

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
  test_self_and_name("test.run", test.run, test, 0)
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
  print("\nSet_strict_mode false suite:")
  local test = make_suite("test", { to_test = true })
  test:set_strict_mode(false)
  local counter = 0
  test:UNTESTED "to_test"
  test "any" (function()
    counter = counter + 1
    if test:in_strict_mode() then
      counter = counter + 10
    end
  end)
  ensure_equals("in strict mode", test:in_strict_mode(), false)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("Sum", counter, 1)
end

do
  print("\nSet_strict_mode true suite:")
  local test = make_suite("test", { to_test = true })
  test:set_strict_mode(true)
  local counter = 0
  test:UNTESTED "to_test"
  test "any" (function()
    counter = counter + 1
    if test:in_strict_mode() then
      counter = counter + 10
    end
  end)
  ensure_equals("in strict mode", test:in_strict_mode(), true)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `[STRICT MODE]': detected TODOs:\n"
   .. "   -- write tests for `to_test'\n\n",
      test:run()
    )
  ensure_equals("Sum", counter, 11)
end

do
  print("\nSingle set_fail_on_first_error false suite:")
  local test = make_suite("test", { })
  test:set_fail_on_first_error(false)
  local counter = 0
  test "fail_one" (function() counter = counter + 1 error("any error", 0) end)
  test "fail_two" (function() counter = counter + 10 error("any error", 0) end)
  ensure_error(
       "test:run()",
       "Suite `test' failed:\n"
    .. " * Test `fail_one': any error\n"
    .. " * Test `fail_two': any error\n",
       test:run()
     )
   ensure_equals("Sum", counter, 11)
end

do
  print("\nSingle set_fail_on_first_error true suite:")
  local test = make_suite("test", { })
  test:set_fail_on_first_error(true)
  local counter = 0
  test "fail_one" (function() counter = counter + 1 error("any error", 0) end)
  test "fail_two" (function() counter = counter + 10 error("any error", 0) end)
  ensure_error(
      "test:run()",
      "Suite `test' failed:\n"
   .. " * Test `fail_one': any error\n"
   .. " * Test `[FAIL ON FIRST ERROR]': FAILED AS REQUESTED\n",
      test:run()
    )
  ensure_equals("Sum", counter, 1)
  print("ABOVE FAIL WAS EXPECTED")
end

do
  print("\nSingle UNTESTED suite:")
  local test = make_suite("test", { to_test = true })
  test:UNTESTED "to_test"
  if test:in_strict_mode() then
    ensure_error(
        "test:run()",
        "Suite `test' failed:\n"
     .. " * Test `[STRICT MODE]': detected TODOs:\n"
     .. "   -- write tests for `to_test'\n\n",
        test:run()
      )
  else ensure_equals("test:run()", test:run(), true) end
end

do
  print("\nSingle TODO suite:")
  local test = make_suite("test", { })
  test:TODO "to_test"
  if test:in_strict_mode() then
    ensure_error(
        "test:run()",
        "Suite `test' failed:\n"
     .. " * Test `[STRICT MODE]': detected TODOs:\n"
     .. "   -- to_test\n\n",
        test:run()
      )
  else ensure_equals("test:run()", test:run(), true) end
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

do
  print("\nRandomseed value test:")
  local test = make_suite("test", {})
  local value, other_value
  test "any" (function() value = math.random() end)
  test "any_other" (function() other_value = math.random() end)
  ensure_equals("test:run()", test:run(), true)
  math.randomseed(12345)
  ensure_equals("random values equal", value == math.random(), true)
  -- math.randomseed(12345)
  -- ensure_equals("test:run()", other_value == math.random(), true)
  -- TODO: we get one randomseed for suite, not for case
  math.randomseed(12346)
  ensure_equals("random values not equal", value == math.random(), false)
end

do
  print("\nSet_up and tear_down test:")
  local test = make_suite("test", {})
  local value, other_value
  local counter = 0
  test:set_up (function()
    math.randomseed(12345)
  end)
  test:tear_down (function()
    counter = counter + 1
  end)
  test "any" (function() value = math.random() end)
  test "any_other" (function() other_value = math.random() end)
  ensure_equals("test:run()", test:run(), true)
  ensure_equals("tear_down results", counter == 2, true)
  math.randomseed(12345)
  ensure_equals("random values equal", value == math.random(), true)
  math.randomseed(12345)
  ensure_equals("random values equal", other_value == math.random(), true)
  math.randomseed(12346)
  ensure_equals("random values not equal", value == math.random(), false)
  ensure_fails_with_substring(
    "double set_up",
    function() test:set_up (function() end) end,
    "set_up duplication"
  )
  ensure_fails_with_substring(
    "double tear_down",
    function() test:tear_down (function() end) end,
    "tear_down duplication"
  )
end

do
  print("\nSet_up test fail:")
  local test = make_suite("test", {})
  test:set_up (function() error("expected error") end)
  test "any" (function() end)
  ensure_error_with_substring(
      "test:run()",
      "Suite `test' failed:\n"
   .. " %* Test `any':(.-) expected error\n",
      test:run()
    )
end

do
  print("\nTear_down test fail:")
  local test = make_suite("test", {})
  test:tear_down (function() error("expected error") end)
  test "any" (function() end)
  ensure_error_with_substring(
      "test:run()",
      "Suite `test' failed:\n"
   .. " %* Test `any':(.-) expected error\n",
      test:run()
    )
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
  test:set_strict_mode(false)
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

  ensure_error_with_substring(
      "test:run()",
      "Suite `test' failed:\n"
   .. " %* Test `func2_two': (.-): Expected error.",
      test:run()
    )
  ensure_equals("product", counter, 2 * 3 * 7 * 11)

  counter = 1
  test:set_strict_mode(true)
  ensure_error_with_substring(
      "test:run()",
      "Suite `test' failed:\n"
   .. " %* Test `func2_two': (.-): Expected error.\n"
   .. " %* Test `%[STRICT MODE%]': detected TODOs:\n"
   .. "   %-%- write tests for `func3'\n"
   .. "   %-%- TODOs can duplicate func names\n"
   .. "   %-%- func4",
      test:run()
    )
  ensure_equals("product", counter, 2 * 3 * 5 * 7 * 11)

  counter = 1
  test:set_fail_on_first_error(true)
  ensure_error_with_substring(
      "test:run()",
      "Suite `test' failed:\n"
   .. " %* Test `func2_two': (.-): Expected error.\n"
   .. " %* Test `%[FAIL ON FIRST ERROR%]': FAILED AS REQUESTED\n",
      test:run()
    )
  print("ABOVE FAIL WAS EXPECTED")
  ensure_equals("product", counter, 2 * 3 * 5 * 7)
end
