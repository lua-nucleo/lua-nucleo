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
      fill_placeholders_ex,
      fill_placeholders,
      fill_curly_placeholders,
      cdata_wrap,
      cdata_cat,
      split_by_char,
      split_by_offset,
      count_substrings,
      kv_concat,
      escape_lua_pattern,
      escape_for_json,
      starts_with,
      ends_with,
      create_escape_subst,
      url_encode,
      string_exports
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter',
        'trim',
        'escape_string',
        'htmlspecialchars',
        'fill_placeholders_ex',
        'fill_placeholders',
        'fill_curly_placeholders',
        'cdata_wrap',
        'cdata_cat',
        'split_by_char',
        'split_by_offset',
        'count_substrings',
        'kv_concat',
        'escape_lua_pattern',
        'escape_for_json',
        'starts_with',
        'ends_with',
        'create_escape_subst',
        'url_encode'
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

test "make_concatter-glue" (function()
  local cat, concat = make_concatter()

  cat "a" "\0" "bc\0" "def\0"

  ensure_equals("concat", concat("{\0}"), "a{\0}\0{\0}bc\0{\0}def\0")
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

test:tests_for "starts_with"

test "starts_with-minimal" (function()
  ensure_equals("trivial", starts_with("", ""), true)
  ensure_equals("strings always start with empty string", starts_with("abc", ""), true)
  ensure_equals("1..1", starts_with("abc", "a"), true)
  ensure_equals("1..2", starts_with("abc", "ab"), true)
  ensure_equals("1..3", starts_with("abc", "abc"), true)
  ensure_equals("1..4", starts_with("abc", "abcb"), false)
  ensure_equals("special char", starts_with("abc", "\000"), false)
  ensure_equals("binary-safe", starts_with("Русский язык велик и могуч", "Русский я"), true)
  ensure_equals("against number", starts_with("foo", 1), false)
  ensure_equals("against boolean", starts_with("foo", false), false)
  ensure_equals("against table", starts_with("foo", {}), false)
  ensure_equals("against nil", starts_with("foo", nil), false)
end)

test:tests_for "ends_with"

test "ends_with-minimal" (function()
  ensure_equals("trivial", ends_with("", ""), true)
  ensure_equals("strings always end with empty string", ends_with("abc", ""), true)
  ensure_equals("1..1", ends_with("abc", "c"), true)
  ensure_equals("1..2", ends_with("abc", "bc"), true)
  ensure_equals("1..3", ends_with("abc", "abc"), true)
  ensure_equals("1..4", ends_with("abc", "abc "), false)
  ensure_equals("special char", ends_with("abc", "\000"), false)
  ensure_equals("binary-safe", ends_with("Русский язык велик и могуч", "к и могуч"), true)
  ensure_equals("against number", ends_with("foo", 1), false)
  ensure_equals("against boolean", ends_with("foo", false), false)
  ensure_equals("against table", ends_with("foo", {}), false)
  ensure_equals("against nil", ends_with("foo", nil), false)
end)

--------------------------------------------------------------------------------

test:tests_for "escape_string"

test "escape_string-minimal" (function ()

  ensure_equals(
       "Equal strings",
       escape_string("simple str without wrong chars"),
       "simple str without wrong chars"
     )

  ensure_equals("escaped str exceptions", escape_string("\009\010"), "\t\n")

  ensure_equals(
      "escaped str",
      escape_string("\000\001\128"),
      "%00%01%80"
    )

  local str_test = ""
  for i = 0, 255 do
    str_test = str_test .. string.char(i)
  end

  ensure_equals("escaped str all symbols 129 - 255",
      escape_string(str_test),
      [[%00%01%02%03%04%05%06%07%08]] .. "\t\n"
   .. [[%0B%0C%0D%0E%0F%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F !"#$%]]
   .. [[&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghij]]
   .. [[klmnopqrstuvwxyz{|}~%7F%80%81%82%83%84%85%86%87%88%89%8A%8B%8C%8D%8E%]]
   .. [[8F%90%91%92%93%94%95%96%97%98%99%9A%9B%9C%9D%9E%9F%A0%A1%A2%A3%A4%A5%]]
   .. [[A6%A7%A8%A9%AA%AB%AC%AD%AE%AF%B0%B1%B2%B3%B4%B5%B6%B7%B8%B9%BA%BB%BC%]]
   .. [[BD%BE%BF%C0%C1%C2%C3%C4%C5%C6%C7%C8%C9%CA%CB%CC%CD%CE%CF%D0%D1%D2%D3%]]
   .. [[D4%D5%D6%D7%D8%D9%DA%DB%DC%DD%DE%DF%E0%E1%E2%E3%E4%E5%E6%E7%E8%E9%EA%]]
   .. [[EB%EC%ED%EE%EF%F0%F1%F2%F3%F4%F5%F6%F7%F8%F9%FA%FB%FC%FD%FE%FF]])

end)
--------------------------------------------------------------------------------

test:tests_for "create_escape_subst"

test "create_escape_subst-minimal" (function ()
  local escape_subst = create_escape_subst("\\%03d")

  local str_test = ""
  for i = 0, 255 do
    str_test = str_test .. string.char(i)
  end

  ensure_equals(
       "Equal strings",
       tostring( str_test ):gsub("[%c%z\128-\255]", escape_subst),
       [[\000\001\002\003\004\005\006\007\008]] .. "\t\n"
    .. [[\011\012\013\014\015\016\017]]
    .. [[\018\019\020\021\022\023\024\025\026\027\028\029\030\031 !"#$%&'()*+]]
    .. [[,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmno]]
    .. [[pqrstuvwxyz{|}~\127\128\129\130\131\132\133\134\135\136\137\138\139\]]
    .. [[140\141\142\143\144\145\146\147\148\149\150\151\152\153\154\155\156\]]
    .. [[157\158\159\160\161\162\163\164\165\166\167\168\169\170\171\172\173\]]
    .. [[174\175\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\]]
    .. [[191\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207\]]
    .. [[208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223\224\]]
    .. [[225\226\227\228\229\230\231\232\233\234\235\236\237\238\239\240\241\]]
    .. [[242\243\244\245\246\247\248\249\250\251\252\253\254\255]]
     )
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

test:test_for "url_encode" (function ()
  ensure_strequals("empty", url_encode(""), "")
  ensure_strequals("simple", url_encode("test"), "test")
  ensure_strequals("test with number", url_encode("test555"), "test555")
  ensure_strequals("test with space", url_encode("test string"), "test+string")
  ensure_strequals(
      "symbols",
      url_encode("1234567890-=!@#$%^&*()_+"),
      "1234567890-%3D%21%40%23%24%25%5E%26%2A%28%29_%2B"
    )
end)

--------------------------------------------------------------------------------

test:UNTESTED 'fill_placeholders_ex'

test:UNTESTED 'fill_curly_placeholders'

test:UNTESTED 'split_by_char'

test:UNTESTED 'split_by_offset'

test:UNTESTED 'count_substrings'

test:UNTESTED 'kv_concat'

test:UNTESTED 'escape_lua_pattern'

test:UNTESTED 'escape_for_json'

--------------------------------------------------------------------------------

assert(test:run())
