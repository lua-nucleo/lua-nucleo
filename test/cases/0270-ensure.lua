--------------------------------------------------------------------------------
-- 0270-ensure.lua: tests for enhanced assertions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local pcall, error = pcall, error

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local loadstring
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring'
      }

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_tvariantequals,
      ensure_strequals,
      ensure_strvariant,
      ensure_strpermutations,
      ensure_error,
      ensure_error_with_substring,
      ensure_fails_with_substring,
      ensure_has_substring,
      ensure_is,
      ensure_exports
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_tvariantequals',
        'ensure_strequals',
        'ensure_strvariant',
        'ensure_strpermutations',
        'ensure_error',
        'ensure_error_with_substring',
        'ensure_fails_with_substring',
        'ensure_has_substring',
        'ensure_is'
      }

local ordered_pairs
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'ordered_pairs'
      }

local newproxy = newproxy or select(
  2,
  table.unpack({
    xpcall(require, function() end, 'newproxy')
  })
)

--------------------------------------------------------------------------------

local test = make_suite("ensure", ensure_exports)

--------------------------------------------------------------------------------

test:test_for "ensure_is" (function()
  local matrix =
  {
    ["number"] = 42;
    ["string"] = "lua-nucleo";
    ["table"] = { };
    ["function"] = function() end;
    ["userdata"] = io.stdout;
    ["thread"] = coroutine.create(function() end);
    ["boolean"] = true;
    ["nil"] = nil;
  }

  for typename, obj in ordered_pairs(matrix) do
    -- positive test
    ensure_is(
        "ensure_is broken for type `" .. typename .. "'",
        obj,
        typename
      )

    -- negative test
    for typename2, obj2 in ordered_pairs(matrix) do
      if typename2 ~= typename then
        ensure_fails_with_substring(
            "ensure_is() is false positive for type `" .. typename .. "'",
            function()
              ensure_is("msg", obj2, typename)
            end,
            "ensure_is failed: msg"
            .. ": actual type `" .. typename2
            .. "', expected type `" .. typename
            .. "'"
          )
      end
    end
  end
end)

--------------------------------------------------------------------------------

test:test_for "ensure_has_substring" (function()
  ensure_has_substring("positive test", "the answer is 42", "42")
  ensure_has_substring("positive test with pattern", "the answer is 42", "%d+")
  ensure_has_substring(
      "positive test with pattern 2",
      "the answer is %d",
      "the answer is %d"
    )

  ensure_strequals(
      "ensure_has_substring return test",
      ensure_has_substring("inner msg", "the answer is 42", '42'),
      "the answer is 42"
    )

  ensure_fails_with_substring(
      "negative test",
      function()
        ensure_has_substring("inner msg", "the answer is 42", 'not 42')
      end,
      "ensure_has_substring failed: inner msg:"
      .. " can't find expected substring `not 42'"
      .. " in string: `the answer is 42'"
    )

  ensure_fails_with_substring(
      "value is not a string",
      function()
        ensure_has_substring("inner msg", false, 'not 42')
      end,
      "ensure_has_substring failed: inner msg:"
      .. " value is not a string"
    )
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_error_with_substring"

test:case "ensure_error_with_substring-is-happy-on-failure" (function()
  local res, err = loadstring("boo")
  local expected_error = _VERSION == 'Lua 5.1'
    and [=[[string "boo"]:1: '=' expected near '<eof>']=]
     or [=[[string "boo"]:1: syntax error near <eof>]=]
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        expected_error,
        res,
        err
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_error_with_substring-complains-on-success" (function()
  local res, err = loadstring("x = 1")
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        "%.*",
        res,
        err
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_error_with_substring failed")
    )
end)

test:case "ensure_error_with_substring-matches-empty-message" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        "", -- use empty substring to match _any_ error message
        res,
        err
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_error_with_substring-is-happy-on-regexp-match" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        ".* near .*",
        res,
        err
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_error_with_substring-complains-on-msg-mismatch" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        "inner msg",
        res,
        err
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_error_with_substring failed")
    )
end)

test:case "ensure_error_with_substring-complains-on-regex-mismatch" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        ".* far .*",
        res,
        err
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_error_with_substring failed")
    )
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_fails_with_substring"

test:case "ensure_fails_with_substring-is-happy-on-failure" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error "Lorem ipsum" end,
        "Lorem ipsum"
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_fails_with_substring-complains-on-success" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() end,
        "%.*"
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_fails_with_substring failed")
    )
end)

test:case "ensure_fails_with_substring-matches-empty-message" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error "Lorem ipsum" end,
        "" -- use empty substring to match _any_ error message
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_fails_with_substring-complains-on-msg-mismatch" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error "Lorem ipsum" end,
        "Dolor sit amet"
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_fails_with_substring failed")
    )
end)

test:case "ensure_fails_with_substring-is-happy-on-regexp-match" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error "Lorem ipsum" end,
        "%w+ ipsum"
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_fails_with_substring-complains-on-regex-mismatch" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error "Lorem ipsum" end,
        "Dolor sit amet"
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_fails_with_substring failed")
    )
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_error"

test:case "ensure_error-is-happy-on-failure" (function()
  local res, err = loadstring("boo")
  local expected_error = _VERSION == 'Lua 5.1'
    and [=[[string "boo"]:1: '=' expected near '<eof>']=]
     or [=[[string "boo"]:1: syntax error near <eof>]=]
  local res, err = pcall(function()
    ensure_error(
        "inner msg",
        expected_error,
        res,
        err
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_error-complains-on-message-mismatch" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error(
        "inner msg",
        "Irrelevant error message",
        res,
        err
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("Irrelevant error message")
    )
end)

test:case "ensure_error-complains-on-success" (function()
  local res, err = loadstring("x = 1")
  local res, err = pcall(function()
    ensure_error(
        "inner msg",
        [=[[string "boo"]:1: '=' expected near '<eof>']=],
        res,
        err
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report the complaint",
      err:find("ensure_error failed")
    )
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_strvariant"

local ensure_strvariant_test = function(expected_success, actual, expected)
  local res, err = pcall(ensure_strvariant, "inner msg", actual, expected)
  if not expected_success then
    ensure("should throw error", not res)
    ensure(
        "should report the complaint",
        err:find("ensure_strvariant failed")
      )
  else
    ensure("should not throw error", res)
  end
end

test:case "ensure_strvariant_simple" (function()
  ensure_strvariant_test(false, "string1", nil)
  ensure_strvariant_test(true, nil, nil)
  ensure_strvariant_test(true, "", "")
  ensure_strvariant_test(true, "str", "str")
  ensure_strvariant_test(false, "str", "str2")
  ensure_strvariant_test(false, "str2", "str")
  ensure_strvariant_test(false, nil, "str")

  ensure_strvariant_test(true, "str", { "str" })
  ensure_strvariant_test(true, "str", { "123", "str" })
  ensure_strvariant_test(false, "str", { "123", "str2" })
  ensure_strvariant_test(false, "str", { "123", "str2", "str3" })
  ensure_strvariant_test(true, "str3", { "123", "str2", "str3" })
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_strpermutations"

local ensure_strpermutations_test = function(
  expected_success,
  actual,
  expected_prefix,
  expected_elements_list,
  expected_sep,
  expected_suffix
)
  local res, err = pcall(
      ensure_strpermutations,
      "inner msg",
      actual,
      expected_prefix,
      expected_elements_list,
      expected_sep,
      expected_suffix
    )
  if not expected_success then
    ensure("should throw error", not res)
    ensure(
        "should report the complaint",
        err:find("ensure_strvariant failed")
      )
  else
    ensure("should not throw error", res)
  end
end

test:case "ensure_strpermutations_simple" (function()
  local abc_arr = { "a", "b", "c" }
  ensure_strpermutations_test(true, "abc", "", abc_arr,"","")
  ensure_strpermutations_test(false, "abd", "", abc_arr,"","")
  ensure_strpermutations_test(true, "acb", "", abc_arr,"","")
  ensure_strpermutations_test(true, "cab", "", abc_arr,"","")
  ensure_strpermutations_test(true, "bac", "", abc_arr,"","")
  ensure_strpermutations_test(true, "bca", "", abc_arr,"","")

  ------------------------------------------------------------------------------

  ensure_strpermutations_test(false, "abc", "!", abc_arr,"","")
  ensure_strpermutations_test(false, "acb", "!", abc_arr,"","")
  ensure_strpermutations_test(false, "cab", "!", abc_arr,"","")
  ensure_strpermutations_test(false, "bac", "!", abc_arr,"","")
  ensure_strpermutations_test(false, "bca", "!", abc_arr,"","")

  ensure_strpermutations_test(true, "!abc", "!", abc_arr,"","")
  ensure_strpermutations_test(true, "!acb", "!", abc_arr,"","")
  ensure_strpermutations_test(true, "!cab", "!", abc_arr,"","")
  ensure_strpermutations_test(true, "!bac", "!", abc_arr,"","")
  ensure_strpermutations_test(true, "!bca", "!", abc_arr,"","")

  ------------------------------------------------------------------------------

  ensure_strpermutations_test(false, "abc", "", abc_arr,"","!")
  ensure_strpermutations_test(false, "acb", "", abc_arr,"","!")
  ensure_strpermutations_test(false, "cab", "", abc_arr,"","!")
  ensure_strpermutations_test(false, "bac", "", abc_arr,"","!")
  ensure_strpermutations_test(false, "bca", "", abc_arr,"","!")

  ensure_strpermutations_test(true, "abc!", "", abc_arr,"","!")
  ensure_strpermutations_test(true, "acb!", "", abc_arr,"","!")
  ensure_strpermutations_test(true, "cab!", "", abc_arr,"","!")
  ensure_strpermutations_test(true, "bac!", "", abc_arr,"","!")
  ensure_strpermutations_test(true, "bca!", "", abc_arr,"","!")

  ------------------------------------------------------------------------------

  ensure_strpermutations_test(false, "abc", "", abc_arr,",","")
  ensure_strpermutations_test(false, "acb", "", abc_arr,",","")
  ensure_strpermutations_test(false, "cab", "", abc_arr,",","")
  ensure_strpermutations_test(false, "bac", "", abc_arr,",","")
  ensure_strpermutations_test(false, "bca", "", abc_arr,",","")

  ensure_strpermutations_test(true, "a,b,c", "", abc_arr,",","")
  ensure_strpermutations_test(true, "a,c,b", "", abc_arr,",","")
  ensure_strpermutations_test(true, "c,a,b", "", abc_arr,",","")
  ensure_strpermutations_test(true, "b,a,c", "", abc_arr,",","")
  ensure_strpermutations_test(true, "b,c,a", "", abc_arr,",","")
  ------------------------------------------------------------------------------

  ensure_strpermutations_test(false, "abc", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(false, "acb", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(false, "cab", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(false, "bac", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(false, "bca", "('", abc_arr,"'+'","')")

  ensure_strpermutations_test(true, "('a'+'b'+'c')", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(true, "('a'+'c'+'b')", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(true, "('c'+'a'+'b')", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(true, "('b'+'a'+'c')", "('", abc_arr,"'+'","')")
  ensure_strpermutations_test(true, "('b'+'c'+'a')", "('", abc_arr,"'+'","')")
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_tvariantequals"

do
  local check = function(msg, actual, expected, is_error_expected)
    local status, err = pcall(ensure_tvariantequals, msg, actual, expected)

    if is_error_expected then
      if status then
        error(msg .. ': error is expected but passed OK')
      end
    else
      if not status then
        error('error is not expected but thrown: ' .. err)
      end
    end
  end

  local check_ok = function(msg, actual, expected)
    check(msg, actual, expected, false)
  end

  local check_fail = function(msg, actual, expected)
    check(msg, actual, expected, true)
  end

  test:case "ensure_tvariantequals-basic" (function()
    check_ok(
      'basic1',
      { 1, 2 },
      {
        { 1 },
        { 1, 2 },
        { 1, 2, 3 }
      }
    )

    check_fail(
      'basic2',
      { 2 },
      {
        { 1 },
        { 1, 2 },
        { 1, 2, 3 }
      }
    )

    check_ok(
      'basic3',
      { a = 1, b = 2 },
      {
        { o = 1 },
        { a = 1, b = 2 },
        { a = 1, b = 2, c = 3 }
      }
    )

    check_fail(
      'basic4',
      { a = 1, b = 0 },
      {
        { o = 1 },
        { a = 1, b = 2 },
        { a = 1, b = 2, c = 3 }
      }
    )

    check_ok(
      'basic5',
      { 0, a = 1, b = 2 },
      {
        { o = 1 },
        { 0, a = 1, b = 2 },
        { 2, a = 1, b = 2 }
      }
    )

    check_fail(
      'basic6',
      { 0, a = 1, b = 2 },
      {
        { 0, a = 1 },
        { 2, a = 1, b = 2 },
        { a = 1, b = 2, c = 3 }
      }
    )
  end)

  test:case "ensure_tvariantequals-shallow-test" (function()
    local t = { 1, 2 }
    check_ok(
      'shallow1',
      { 7, t },
      {
        { 1 },
        { 1, 2, 3 },
        { 7, t }
      }
    )

    check_fail(
      'shallow2',
      { 7, t },
      {
        { 1 },
        { 1, 2, 3 },
        { 7, { 1, 2 } }
      }
    )
  end)

  test:case "ensure_tvariantequals-wrong-expected" :BROKEN_IF(not newproxy) (
    function()
      local check_wrong = function(name, value)
        check_fail(
          'wrong-expected-' .. name,
          { 7 },
          {
            { 1 },
            { 7 },
            value
          }
        )
      end

      check_wrong('boolean', true)
      check_wrong('number', 1)
      check_wrong('string', 'text')
      check_wrong('function', function() end)
      check_wrong('userdata', newproxy())
    end
  )
end

--------------------------------------------------------------------------------

-- TODO: Write tests
--       https://github.com/lua-nucleo/lua-nucleo/issues/13
test:UNTESTED "ensure"
test:UNTESTED "ensure_equals"
test:UNTESTED "ensure_tdeepequals"
test:UNTESTED "ensure_returns"
test:UNTESTED "ensure_strequals"
test:UNTESTED "ensure_strlist"
test:UNTESTED "ensure_aposteriori_probability"
test:UNTESTED "ensure_tequals"
