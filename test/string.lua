-- string.lua: tests for string-related tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local ensure,
      ensure_equals,
      ensure_strequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals'
      }

local make_concatter,
      trim,
      escape_string,
      htmlspecialchars,
      string_exports
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter',
        'trim',
        'escape_string',
        'htmlspecialchars'
      }

--------------------------------------------------------------------------------

local test = make_suite("string", string_exports)

--------------------------------------------------------------------------------

test:tests_for "make_concatter"

test "make_concatter-basic" (function()
  local cat, concat = make_concatter()

  ensure_equals("cat is function", type(cat), "function")
  ensure_equals("concat is function", type(concat), "function")

  ensure_equals("cat returns self", cat("42"), cat)
  ensure_equals("concat on single element", concat(), "42")
end)

test "make_concatter-empty" (function()
  local cat, concat = make_concatter()

  ensure_equals("concat on empty data is empty string", concat(), "")
end)

test "make_concatter-simple" (function()
  local cat, concat = make_concatter()

  cat "a"
  cat "bc" (42)
  cat "" "d" ""

  ensure_equals("concat", concat(), "abc42d")
end)

test "make_concatter-embedded-zeroes" (function()
  local cat, concat = make_concatter()

  cat "a" "\0" "bc\0" "def\0"

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

test "escape_string-minimal"(
function ()
  ensure_equals("Equal strings",escape_string("simple str without wrong chars"),"simple str without wrong chars")
  ensure_equals("escaped str",escape_string(string.char(0)..string.char(1)),"%00%01")
end)

--------------------------------------------------------------------------------

test:tests_for "htmlspecialchars"

test "htmlspecialchars-minimal"(
function ()
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


assert(test:run())
