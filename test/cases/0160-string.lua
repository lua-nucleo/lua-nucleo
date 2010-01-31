-- 0160-string.lua: tests for string-related tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals'
      }

local make_concatter,
      trim,
      escape_string,
      htmlspecialchars,
      fill_placeholders,
      cdata_wrap,
      cdata_cat,
      string_exports
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter',
        'trim',
        'escape_string',
        'htmlspecialchars',
        'fill_placeholders',
        'cdata_wrap',
        'cdata_cat'
      }

--------------------------------------------------------------------------------

local test = make_suite("string", string_exports)

--------------------------------------------------------------------------------

test:tests_for "make_concatter"

test "make_concatter-basic" (function()
  local cat, concat, buf = make_concatter()

  ensure_equals("cat is function", type(cat), "function")
  ensure_equals("concat is function", type(concat), "function")
  ensure_equals("buf is table", type(buf), "table")

  ensure_equals("cat returns self", cat("42"), cat)
  ensure_tequals("buf has single element", buf, { "42" })
  ensure_equals("concat on single element", concat(), "42")
end)

test "make_concatter-empty" (function()
  local cat, concat, buf = make_concatter()

  ensure_tequals("buf is empty on empty data", buf, { })
  ensure_equals("concat on empty data is empty string", concat(), "")
end)

test "make_concatter-simple" (function()
  local cat, concat, buf = make_concatter()

  cat "a"
  cat "bc" (42)
  cat "" "d" ""

  ensure_tequals("buf", buf, { "a", "bc", 42, "", "d", "" })
  ensure_equals("concat", concat(), "abc42d")
end)

test "make_concatter-embedded-zeroes" (function()
  local cat, concat, buf = make_concatter()

  cat "a" "\0" "bc\0" "def\0"

  ensure_tequals("buf", buf, { "a", "\0", "bc\0", "def\0" })
  ensure_equals("concat", concat(), "a\0bc\0def\0")
end)

--------------------------------------------------------------------------------

test:tests_for "trim"

test "trim-basic" (function()
  ensure_equals("empty string", trim(""), "")
  ensure_equals("none", trim("a"), "a")
  ensure_equals("left", trim(" b"), "b")
  ensure_equals("right", trim("c "), "c")
  ensure_equals("both", trim(" d "), "d")
  ensure_equals("middle", trim("e f"), "e f")
  ensure_equals("many", trim("\t \t    \tg  \th\t    \t "), "g  \th")
end)

--------------------------------------------------------------------------------

test:tests_for "escape_string"

test "escape_string-minimal" (function ()
  ensure_equals("Equal strings",escape_string("simple str without wrong chars"),"simple str without wrong chars")
  ensure_equals("escaped str",escape_string(string.char(0)..string.char(1)),"%00%01")
end)

--------------------------------------------------------------------------------

test:tests_for "htmlspecialchars"

test "htmlspecialchars-minimal" (function ()
  -- Uses texts from PHP 5.3.0 htmlspecialchars tests

  local buf = {} -- We need special cat, not using make_concatter
  local cat = function(v)
    -- Matching var_dump for strings
    arguments("string", v)
    buf[#buf + 1] = 'string('
    buf[#buf + 1] = #v
    buf[#buf + 1] = ') "'
    buf[#buf + 1] = v -- Unquoted
    buf[#buf + 1] = "\"\n"
  end

  -- normal string
  cat (htmlspecialchars("<br>Testing<p>New file.</p> "))

  -- long string
  cat (htmlspecialchars("<br>Testing<p>New file.</p><p><br>File <b><i><u>WORKS!!!</i></u></b></p><br><p>End of file!!!</p>"))

  -- checking behavior of quote
  cat (htmlspecialchars("A 'quote' is <b>bold</b>"))

  local expected = [[
string(46) "&lt;br&gt;Testing&lt;p&gt;New file.&lt;/p&gt; "
string(187) "&lt;br&gt;Testing&lt;p&gt;New file.&lt;/p&gt;&lt;p&gt;&lt;br&gt;File &lt;b&gt;&lt;i&gt;&lt;u&gt;WORKS!!!&lt;/i&gt;&lt;/u&gt;&lt;/b&gt;&lt;/p&gt;&lt;br&gt;&lt;p&gt;End of file!!!&lt;/p&gt;"
string(46) "A &apos;quote&apos; is &lt;b&gt;bold&lt;/b&gt;"
]]

  ensure_strequals("escaped", table.concat(buf), expected)
end)

--------------------------------------------------------------------------------

test:tests_for 'cdata_wrap'
               'cdata_cat'

--------------------------------------------------------------------------------

test "cdata_wrap-cdata_cat" (function ()
  local check = function(value, expected)
    do
      local actual = cdata_wrap(value)
      ensure_strequals("cdata_wrap", actual, expected)
    end

    do
      local cat, concat = make_concatter()
      cdata_cat(cat, value)
      ensure_strequals("cdata_cat", concat(), expected)
    end
  end

  check("", "<![CDATA[]]>")
  check("embedded\0zero", "<![CDATA[embedded\0zero]]>")
  check("<![CDATA[xxx]]>", "<![CDATA[<![CDATA[xxx]]]]><![CDATA[>]]>")
end)

--------------------------------------------------------------------------------

test:test_for "fill_placeholders" (function ()
  ensure_strequals("both empty", fill_placeholders("", {}), "")
  ensure_strequals("empty dict", fill_placeholders("test", {}), "test")
  ensure_strequals("empty str", fill_placeholders("", { a = 42 }), "")
  ensure_strequals("missing key", fill_placeholders("$(b)", { a = 42 }), "$(b)")

  ensure_strequals("bad format", fill_placeholders("$a", { a = 42 }), "$a")
  ensure_strequals("missing right brace", fill_placeholders("$a)", { a = 42 }), "$a)")
  ensure_strequals("missing left brace", fill_placeholders("$(a", { a = 42 }), "$(a")

  ensure_strequals("ok", fill_placeholders("a = `$(a)'", { a = 42 }), "a = `42'")
  ensure_tequals("no extra data", { fill_placeholders("a = `$(a)'", { a = 42 }) }, { "a = `42'" })

  ensure_strequals("extra key", fill_placeholders("a = `$(a)'", { a = 42, b = 43 }), "a = `42'")
  ensure_strequals("two keys", fill_placeholders("`$(key)' = `$(value)'", { key = "a", value = 42 }), "`a' = `42'")

  ensure_strequals("empty string key", fill_placeholders("`$()'", { [""] = 42 }), "`42'")

  ensure_strequals("extra braces", fill_placeholders("$(a `$(a)')", { a = 42 }), "$(a `$(a)')")
  ensure_strequals("extra right brace", fill_placeholders("`$(a)')", { a = 42 }), "`42')")
end)

--------------------------------------------------------------------------------

assert(test:run())
