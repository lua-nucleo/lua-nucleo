--------------------------------------------------------------------------------
-- 0270-ensure.lua: tests for enhanced assertions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local pcall, loadstring, error = pcall, loadstring, error

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_strequals,
      ensure_error,
      ensure_error_with_substring,
      ensure_fails,
      ensure_fails_with_substring,
      ensure_has_substring,
      ensure_is,
      ensure_exports
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_strequals',
        'ensure_error',
        'ensure_error_with_substring',
        'ensure_fails',
        'ensure_fails_with_substring',
        'ensure_has_substring',
        'ensure_is'
      }

local ordered_pairs
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'ordered_pairs'
      }

local create_error_object
      = import 'lua-nucleo/error.lua'
      {
        'create_error_object'
      }

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
  local res, err = pcall(function()
    ensure_error_with_substring(
        "inner msg",
        [=[[string "boo"]:1: '=' expected near '<eof>']=],
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

test:tests_for "ensure_fails"

test:case "ensure_fails-is-happy-on-failure" (function()
  local res, err = pcall(function()
    ensure_fails(
        "inner msg",
        function() error "Lorem ipsum" end
      )
  end)
  ensure("should not throw error", res)
end)

test:case "ensure_fails-complains-on-success" (function()
  local res, err = pcall(function()
    ensure_fails(
        "inner msg",
        function() end
      )
  end)
  ensure("should throw error", not res)
  ensure(
      "should report error msg",
      err:find("inner msg")
    )
  ensure(
      "should report the complaint",
      err:find("ensure_fails failed")
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

test:case "ensure_fails_with_substring-supports-error-object" (function()
  local res, err = pcall(function()
    ensure_fails_with_substring(
        "inner msg",
        function() error(create_error_object("Ipsum")) end,
        "Ipsum"
      )
  end)
  ensure("should not throw error", res)
end)

--------------------------------------------------------------------------------

test:tests_for "ensure_error"

test:case "ensure_error-is-happy-on-failure" (function()
  local res, err = loadstring("boo")
  local res, err = pcall(function()
    ensure_error(
        "inner msg",
        [=[[string "boo"]:1: '=' expected near '<eof>']=],
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

-- TODO: Write tests
--       https://github.com/lua-nucleo/lua-nucleo/issues/13
test:UNTESTED "ensure"
test:UNTESTED "ensure_equals"
test:UNTESTED "ensure_tdeepequals"
test:UNTESTED "ensure_returns"
test:UNTESTED "ensure_strequals"
test:UNTESTED "ensure_aposteriori_probability"
test:UNTESTED "ensure_tequals"
