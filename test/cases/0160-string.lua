--------------------------------------------------------------------------------
-- 0160-string.lua: tests for string-related tools
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local unpack = unpack or table.unpack
local newproxy = newproxy or select(
    2,
    unpack({
        xpcall(require, function() end, 'newproxy')
      })
  )

--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local loadstring
      = import 'lua-nucleo/legacy.lua'
      {
        'loadstring'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_strvariant,
      ensure_strlist,
      ensure_tequals,
      ensure_returns,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_strvariant',
        'ensure_strlist',
        'ensure_tequals',
        'ensure_returns',
        'ensure_fails_with_substring'
      }

local make_concatter,
      trim,
      escape_string,
      htmlspecialchars,
      fill_placeholders_ex,
      fill_placeholders,
      fill_curly_placeholders,
      fill_placeholders_with_defaults,
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
      integer_to_string_with_base,
      cut_with_ellipsis,
      number_to_string,
      serialize_number,
      get_escaped_chars_in_ranges,
      tjson_simple,
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
        'fill_placeholders_with_defaults',
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
        'url_encode',
        'integer_to_string_with_base',
        'cut_with_ellipsis',
        'number_to_string',
        'serialize_number',
        'get_escaped_chars_in_ranges',
        'tjson_simple'
      }

local ordered_pairs
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'ordered_pairs'
      }

local tisarray_not
      = import 'lua-nucleo/table-utils.lua'
      {
        'tisarray_not'
      }

local math_pi = math.pi
local table_concat = table.concat

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
  ensure_equals("against table", starts_with("foo", { }), false)
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
  ensure_equals("against table", ends_with("foo", { }), false)
  ensure_equals("against nil", ends_with("foo", nil), false)
end)

--------------------------------------------------------------------------------

test:tests_for "escape_string"

test "escape_string-minimal" (function()

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

test "create_escape_subst-minimal" (function()
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

test "htmlspecialchars-minimal" (function()
  -- Uses texts from PHP 5.3.0 htmlspecialchars tests

  local buf = { } -- We need special cat, not using make_concatter
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

test:tests_for "escape_lua_pattern"

test "escape_lua_pattern-basic" (function()
  ensure_strequals(
      "escapinng lua pattern",
      escape_lua_pattern("abc^$()%.[]*+-?\0xyz"),
      "abc%^%$%(%)%%%.%[%]%*%+%-%?%zxyz"
    )
  ensure_strequals(
      "no escapinng",
      escape_lua_pattern("just normal string 12345"),
      "just normal string 12345"
    )
end)

test "escape_lua_pattern-find" (function()
  local cat, concat = make_concatter()
  for i = 0, 255 do
    cat(string.char(i))
  end
  local input_string = concat() -- contains all possible symbols

  for i = 0, 255 do -- check all possible symbols
    local char = string.char(i)
    local i_start, i_end = input_string:find(escape_lua_pattern(char))
    ensure("match for " .. char .. " is found", i_start)
    ensure_equals("match for " .. char .. " is one symbol", i_start, i_end)
    ensure_equals("position for " .. char .. " is correct", i_start, i + 1)
  end
end)

--------------------------------------------------------------------------------

test:tests_for 'cdata_wrap'
               'cdata_cat'

--------------------------------------------------------------------------------

test "cdata_wrap-cdata_cat" (function()
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

test:tests_for "split_by_char"

test "split_by_char-basic" (function()
  ensure_fails_with_substring(
      "both empty",
      function()
        split_by_char("", "")
      end,
      "Invalid delimiter"
    )
  ensure_fails_with_substring(
      "empty delimiter",
      function()
        split_by_char("abc", "")
      end,
      "Invalid delimiter"
    )
  ensure_fails_with_substring(
      "empty delimiter & bad arg type for string",
      function()
        split_by_char(1, "")
      end,
      "Param str must be a string"
    )

  ensure_tequals("empty string", split_by_char("", " "), { })

  -- NOTE: Test logic for split_* based on reversability of spliting:
  -- split_by_char("mLoremIpsum", "m") must return { "", "Lore", "Ipsu", "" }.
  ensure_tequals(
      "string explode",
      split_by_char("mLoremIpsum", "m"),
      { "", "Lore", "Ipsu", "" }
    )
  ensure_strequals(
      "reversability: string implode after explode",
      table_concat(split_by_char("mLoremIpsum", "m"), "m"),
      "mLoremIpsum"
    )
  ensure_tequals("trailing delimiter", split_by_char("t ", " "), { "t", "" })
  ensure_tequals("leading delimiter", split_by_char(" t", " "), { "", "t" })
  ensure_tequals(
      "leading and trailing delimiter",
      split_by_char(" t ", " "),
      { "", "t", "" }
    )
  ensure_tequals(
      "word not divided",
      split_by_char("Lorem!", "t"),
      { "Lorem!" }
    )
  ensure_tequals(
      "phrase with escapes",
      split_by_char("\nLorem \tipsum?#$%^&*()_+|~/\t \001dolor \007sit\n", " "),
      { "\nLorem", "\tipsum?#$%^&*()_+|~/\t", "\001dolor", "\007sit\n" }
    )
  ensure_tequals(
      "phrase with escapes and zero",
      split_by_char("\nLorem \tipsum?#$%^&*()_+|~/\t \0dolor \007sit.\n", " "),
      { "\nLorem", "\tipsum?#$%^&*()_+|~/\t", "\0dolor", "\007sit.\n" }
    )
  ensure_fails_with_substring(
      "space string, delimiter with escapes and zero",
      function()
        split_by_char(" ", "\nLorem \tipsum?#$%^&*()_+|~/\t \0dolor \007sit.\n")
      end,
      "Invalid delimiter"
    )
  ensure_fails_with_substring(
      "empty string & delimiter with escapes and zero",
      function()
        split_by_char("", "\nLorem \tipsum?#$%^&*()_+|~/\t \0dolor \007sit.\n")
      end,
      "Invalid delimiter"
    )
  ensure_tequals(
      "quirky delimiter",
      split_by_char("\000\000", "\000"),
      { "", "", "" }
    )
  ensure_tequals(
      "rich text and zero delimiter",
      split_by_char("Барсик!", "\000"),
      { "Барсик!" }
    )
end)

--------------------------------------------------------------------------------

test:tests_for 'split_by_offset'

test:test "split_by_offset-basic" (function()
  local BASIC_STRING = "Lorem ipsum dolor sit amet"

  ensure_fails_with_substring(
      "test with offset > #str",
      function()
        split_by_offset(BASIC_STRING, 100)
      end,
      "offset greater than str length"
    )
  ensure_fails_with_substring(
      "test with offset = #str+1",
      function()
        split_by_offset(BASIC_STRING, 1 + #BASIC_STRING)
      end,
      "offset greater than str length"
    )
  ensure_returns(
      "offset < 0",
      2,
      { BASIC_STRING, BASIC_STRING },
      split_by_offset(BASIC_STRING, -1)
    )
  ensure_returns(
      "offset = 0",
      2,
      { "", BASIC_STRING },
      split_by_offset(BASIC_STRING, 0)
    )
  ensure_returns(
      "offset = 1",
      2,
      { "L", "orem ipsum dolor sit amet" },
      split_by_offset(BASIC_STRING, 1)
    )
  ensure_returns(
      "max offset",
      2,
      { BASIC_STRING, "" },
      split_by_offset(BASIC_STRING, #BASIC_STRING)
    )
  ensure_returns(
      "max offset and skip 0",
      2,
      { BASIC_STRING, "" },
      split_by_offset(BASIC_STRING, #BASIC_STRING, 0)
    )
  ensure_returns(
      "max offset and skip -2",
      2,
      { BASIC_STRING, "et" },
      split_by_offset(BASIC_STRING, #BASIC_STRING, -2)
    )
  ensure_returns(
      "max offset and skip -max",
      2,
      { BASIC_STRING, BASIC_STRING },
      split_by_offset(BASIC_STRING, #BASIC_STRING, -#BASIC_STRING)
    )
  ensure_returns(
      "max offset and skip under begin",
      2,
      { BASIC_STRING, BASIC_STRING },
      split_by_offset(BASIC_STRING, #BASIC_STRING, -1 - #BASIC_STRING)
    )
  ensure_returns(
      "max offset and skip max",
      2,
      { BASIC_STRING, "" },
      split_by_offset(BASIC_STRING, #BASIC_STRING, 1 + #BASIC_STRING)
    )
  ensure_returns(
      "offset 1 and skip 0",
      2,
      { "L", "orem ipsum dolor sit amet" },
      split_by_offset(BASIC_STRING, 1, 0)
    )
  ensure_returns(
      "offset 1 and skip 5",
      2,
      { "L", "ipsum dolor sit amet" },
      split_by_offset(BASIC_STRING, 1, 5)
    )
  ensure_returns(
      "offset 5 and skip 5",
      2,
      { "Lorem", "m dolor sit amet" },
      split_by_offset(BASIC_STRING, 5, 5)
    )
end)

--------------------------------------------------------------------------------

test:tests_for "fill_placeholders_ex"

test "fill_placeholders_ex-basic" (function()
  ensure_strequals(
      "both empty",
      fill_placeholders_ex("%$%((.-)%)", "", { }),
      ""
    )
  ensure_strequals(
      "empty dict",
      fill_placeholders_ex("%$%((.-)%)", "test", { }),
      "test"
    )
  ensure_strequals(
      "empty str",
      fill_placeholders_ex("%$%((.-)%)", "", { a = 42 }),
      ""
    )
  ensure_strequals(
      "missing key",
      fill_placeholders_ex("%$%((.-)%)", "$(b)", { a = 42 }),
      "$(b)"
    )
  ensure_strequals(
      "bad format",
      fill_placeholders_ex("%$%((.-)%)", "$a", { a = 42 }),
      "$a"
    )
  ensure_strequals(
      "missing right brace",
      fill_placeholders_ex("%$%((.-)%)", "$a)", { a = 42 }),
      "$a)"
    )
  ensure_strequals(
      "missing left brace",
      fill_placeholders_ex("%$%((.-)%)", "$(a", { a = 42 }),
      "$(a"
    )
  ensure_strequals(
      "proper usage",
      fill_placeholders_ex("%$%((.-)%)", "a = `$(a)'", { a = 42 }),
      "a = `42'"
    )
  ensure_tequals(
      "check for no extra data being generated",
      { fill_placeholders_ex("%$%((.-)%)", "a = `$(a)'", { a = 42 }) },
      { "a = `42'" }
    )
  ensure_strequals(
      "extra key",
      fill_placeholders_ex("%$%((.-)%)", "a = `$(a)'", { a = 42, b = 43 }),
      "a = `42'"
    )
  ensure_strequals(
      "two keys",
      fill_placeholders_ex(
          "%$%((.-)%)", "`$(key)' = `$(value)'",
          { key = "a", value = 42 }
        ),
      "`a' = `42'"
    )
  ensure_strequals(
      "empty string key",
      fill_placeholders_ex("%$%((.-)%)", "`$()'", { [""] = 42 }),
      "`42'"
    )
  ensure_strequals(
      "extra braces",
      fill_placeholders_ex("%$%((.-)%)", "$(a `$(a)')", { a = 42 }),
      "$(a `$(a)')"
    )
  ensure_strequals(
      "extra braces pragmatic",
      fill_placeholders_ex("%$%((.-)%)", "$(a `$(a)')", { ["a `$(a"] = 42 }),
      "42')"
    )
  ensure_strequals(
      "extra right round brace",
      fill_placeholders_ex("%$%((.-)%)", "`$(a)')", { a = 42 }),
      "`42')"
    )
  ensure_strequals(
      "extra right curly brace",
      fill_placeholders_ex("%$%((.-)%)", "`$(a)'}", { a = 42 }),
      "`42'}"
    )
  ensure_strequals(
      "curly: both empty",
      fill_placeholders_ex("%${(.-)}", "", { }),
      ""
    )
  ensure_strequals(
      "curly: empty dict",
      fill_placeholders_ex("%${(.-)}", "test", { }),
      "test"
    )
  ensure_strequals(
      "curly: empty str",
      fill_placeholders_ex("%${(.-)}", "", { a = 42 }),
      ""
    )
  ensure_strequals(
      "curly: missing key",
      fill_placeholders_ex("%${(.-)}", "${b}", { a = 42 }),
      "${b}"
    )
  ensure_strequals(
      "curly: bad format",
      fill_placeholders_ex("%${(.-)}", "$a", { a = 42 }),
      "$a"
    )
  ensure_strequals(
      "curly: missing right brace",
      fill_placeholders_ex("%${(.-)}", "$a}", { a = 42 }),
      "$a}"
    )
  ensure_strequals(
      "curly: missing left brace",
      fill_placeholders_ex("%${(.-)}", "${a", { a = 42 }),
      "${a"
    )
  ensure_strequals(
      "curly: proper usage",
      fill_placeholders_ex("%${(.-)}", "a = `${a}'", { a = 42 }),
      "a = `42'"
    )
  ensure_tequals(
      "curly: check for no extra data being generated",
      { fill_placeholders_ex("%${(.-)}", "a = `${a}'", { a = 42 }) },
      { "a = `42'" }
    )
  ensure_strequals(
      "curly: extra key",
      fill_placeholders_ex("%${(.-)}", "a = `${a}'", { a = 42, b = 43 }),
      "a = `42'"
    )
  ensure_strequals(
      "curly: two keys",
      fill_placeholders_ex(
          "%${(.-)}", "`${key}' = `${value}'",
          { key = "a", value = 42 }
        ),
      "`a' = `42'"
    )
  ensure_strequals(
      "curly: empty string key",
      fill_placeholders_ex("%${(.-)}", "`${}'", { [""] = 42 }),
      "`42'"
    )
  ensure_strequals(
      "curly: extra braces",
      fill_placeholders_ex("%${(.-)}", "${a `${a}'}", { a = 42 }),
      "${a `${a}'}"
    )
  ensure_strequals(
      "curly: extra braces pragmatic",
      fill_placeholders_ex("%${(.-)}", "${a `${a}'}", { ["a `${a"] = 42 }),
      "42'}"
    )
  ensure_strequals(
      "curly: extra right brace",
      fill_placeholders_ex("%${(.-)}", "`${a}'}", { a = 42 }),
      "`42'}"
    )
  ensure_strequals(
      "curly: extra round braces",
      fill_placeholders_ex("%${(.-)}", "${a `${a}'}", { a = 42 }),
      "${a `${a}'}"
    )
  ensure_strequals(
      "curly: extra right curly brace",
      fill_placeholders_ex("%${(.-)}", "`${a}'}", { a = 42 }),
      "`42'}"
    )
  ensure_strequals(
      "curly: extra right round brace",
      fill_placeholders_ex("%${(.-)}", "`${a}')", { a = 42 }),
      "`42')"
    )
end)

--------------------------------------------------------------------------------

test:test_for "fill_placeholders" (function()
  ensure_strequals("both empty", fill_placeholders("", { }), "")
  ensure_strequals("empty dict", fill_placeholders("test", { }), "test")
  ensure_strequals("empty str", fill_placeholders("", { a = 42 }), "")
  ensure_strequals(
      "missing key",
      fill_placeholders("$(b)", { a = 42 }),
      "$(b)"
    )

  ensure_strequals("bad format", fill_placeholders("$a", { a = 42 }), "$a")
  ensure_strequals(
      "missing right brace",
      fill_placeholders("$a)", { a = 42 }),
      "$a)"
    )
  ensure_strequals(
      "missing left brace",
      fill_placeholders("$(a", { a = 42 }),
      "$(a"
    )

  ensure_strequals(
      "proper usage",
      fill_placeholders("a = `$(a)'", { a = 42 }),
      "a = `42'"
    )
  ensure_tequals(
      "check for no extra data being generated",
      { fill_placeholders("a = `$(a)'", { a = 42 }) },
      { "a = `42'" }
    )

  ensure_strequals(
      "extra key",
      fill_placeholders("a = `$(a)'", { a = 42, b = 43 }),
      "a = `42'"
    )
  ensure_strequals(
      "two keys",
      fill_placeholders("`$(key)' = `$(value)'", { key = "a", value = 42 }),
      "`a' = `42'"
    )

  ensure_strequals(
      "empty string key",
      fill_placeholders("`$()'", { [""] = 42 }),
      "`42'"
    )

  ensure_strequals(
      "extra braces",
      fill_placeholders("$(a `$(a)')", { a = 42 }),
      "$(a `$(a)')"
    )
  ensure_strequals(
      "extra braces pragmatic",
      fill_placeholders("$(a `$(a)')", { ["a `$(a"] = 42 }),
      "42')"
    )
  ensure_strequals(
      "extra right brace",
      fill_placeholders("`$(a)')", { a = 42 }),
      "`42')"
    )
end)

--------------------------------------------------------------------------------

test:test_for "fill_curly_placeholders" (function()
  ensure_strequals(
      "both empty",
      fill_curly_placeholders("", { }),
      ""
    )
  ensure_strequals(
      "empty dict",
      fill_curly_placeholders("test", { }),
      "test"
    )
  ensure_strequals(
      "empty str",
      fill_curly_placeholders("", { a = 42 }),
      ""
    )
  ensure_strequals(
      "missing key",
      fill_curly_placeholders("${b}", { a = 42 }),
      "${b}"
    )
  ensure_strequals(
      "bad format",
      fill_curly_placeholders("$a", { a = 42 }),
      "$a"
    )
  ensure_strequals(
      "missing right brace",
      fill_curly_placeholders("$a}", { a = 42 }),
      "$a}"
    )
  ensure_strequals(
      "missing left brace",
      fill_curly_placeholders("${a", { a = 42 }),
      "${a"
    )
  ensure_strequals(
      "proper usage",
      fill_curly_placeholders("a = `${a}'", { a = 42 }),
      "a = `42'"
    )
  ensure_tequals(
      "check for no extra data being generated",
      { fill_curly_placeholders("a = `${a}'", { a = 42 }) },
      { "a = `42'" }
    )
  ensure_strequals(
      "extra key",
      fill_curly_placeholders("a = `${a}'", { a = 42, b = 43 }),
      "a = `42'"
    )
  ensure_strequals(
      "two keys",
      fill_curly_placeholders("`${key}' = `${value}'", { key = "a", value = 42 }),
      "`a' = `42'"
    )
  ensure_strequals(
      "empty string key",
      fill_curly_placeholders("`${}'", { [""] = 42 }),
      "`42'"
    )
  ensure_strequals(
      "extra braces",
      fill_curly_placeholders("${a `${a}'}", { a = 42 }),
      "${a `${a}'}"
    )
  ensure_strequals(
      "extra braces pragmatic",
      fill_curly_placeholders("${a `${a}'}", { ["a `${a"] = 42 }),
      "42'}"
    )
  ensure_strequals(
      "extra right brace",
      fill_curly_placeholders("`${a}'}", { a = 42 }),
      "`42'}"
    )
end)

--------------------------------------------------------------------------------

test:test_for "fill_placeholders_with_defaults" (function()
  ensure_strequals(
      "both empty",
      fill_placeholders_with_defaults("", { }),
      ""
    )
  ensure_strequals(
      "empty dict",
      fill_placeholders_with_defaults("test", { }),
      "test"
    )
  ensure_strequals(
      "empty str",
      fill_placeholders_with_defaults("", { a = 42 }),
      ""
    )
  ensure_strequals(
      "missing key",
      fill_placeholders_with_defaults("%{b}", { a = 42 }),
      "%{b}"
    )
  ensure_strequals(
      "format with $",
      fill_placeholders_with_defaults("${a}", { a = 42 }),
      "${a}"
    )
  ensure_strequals(
      "bad format",
      fill_placeholders_with_defaults("%a", { a = 42 }),
      "%a"
    )
  ensure_strequals(
      "missing right brace",
      fill_placeholders_with_defaults("%a}", { a = 42 }),
      "%a}"
    )
  ensure_strequals(
      "missing left brace",
      fill_placeholders_with_defaults("%{a", { a = 42 }),
      "%{a"
    )
  ensure_strequals(
      "extra key",
      fill_placeholders_with_defaults("a = `%{a}'", { a = 42, b = 43 }),
      "a = `42'"
    )
  ensure_strequals(
      "two keys",
      fill_placeholders_with_defaults("`%{key}' = `%{value}'", { key = "a", value = 42 }),
      "`a' = `42'"
    )
  ensure_strequals(
      "with default",
      fill_placeholders_with_defaults("%{a=43}", { a = 42 }),
      "42"
    )
  ensure_strequals(
      "with default, missing key",
      fill_placeholders_with_defaults("%{a=43}", { b = 42 }),
      "43"
    )
  ensure_strequals(
      "empty default",
      fill_placeholders_with_defaults("%{a=}", { a = 42}),
      "42"
    )
  ensure_strequals(
      "empty default, missing key",
      fill_placeholders_with_defaults("%{a=}", { b = 42}),
      ""
    )
end)

--------------------------------------------------------------------------------

test:tests_for 'count_substrings'

test:test "count_substrings-basic" (function()
  local BASIC_STRING = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
  ensure_fails_with_substring(
      "both empty",
      function()
        count_substrings("", "")
      end,
      "substring must be not empty"
    )
  ensure_equals("str empty", count_substrings("", BASIC_STRING), 0)
  ensure_fails_with_substring(
      "substr empty",
      function()
        count_substrings(BASIC_STRING, "")
      end,
      "substring must be not empty"
    )
  ensure_equals("str equal substr", count_substrings("t", "t"), 1)
  ensure_equals("zero count", count_substrings(BASIC_STRING, "est"), 0)
  ensure_equals("positive count", count_substrings(BASIC_STRING, "o"), 4)
  ensure_equals(
      "positive count for word",
      count_substrings(BASIC_STRING, "sit"),
      1
    )
  ensure_equals(
      "special character string",
      count_substrings(
          "\nLorem \tipsum?#$%^&*()_+|~/\t \0dolor \007sit.\n",
          "o"
        ),
      3
    )
end)

--------------------------------------------------------------------------------

test:tests_for 'kv_concat'

test:test "kv_concat-basic" (function()
  ensure_strequals("empty, no iterator and pairs glue", kv_concat({ }, ""), "")
  ensure_strequals("empty, no iterator", kv_concat({ }, "", ""), "")
  ensure_strequals("empty table, no iterator", kv_concat({ }, " ", " "), "")
  ensure_strequals("empty table", kv_concat({ }, " ", " ", pairs), "")
  ensure_strequals(
      "pairs iterator",
      kv_concat({ 3, "2", 1, "!?#$%^&*()_+|~/" }, " ", ",", pairs),
      "1 3,2 2,3 1,4 !?#$%^&*()_+|~/"
    )
  ensure_strequals(
      "ipairs iterator",
      kv_concat({ 3, "2", 1, "!?#$%^&*()_+|~/" }, " ", ",", ipairs),
      "1 3,2 2,3 1,4 !?#$%^&*()_+|~/"
    )
  ensure_strequals("empty table, ipairs", kv_concat({ }, " ", ",", ipairs), "")
  ensure_strequals(
      "ipairs cut not an integer indexes",
      kv_concat({ x = 3, y = "2", 1, "!?#$%^&*()_+|~/" }, "=", ",", ipairs),
      "1=1,2=!?#$%^&*()_+|~/"
    )
  -- Feature: We have to use very slow ordered_pairs() due to undefined
  -- traversal order with regular pairs(), which can break compatibility
  -- between Lua 5.1 and LuaJIT 2
  ensure_strequals(
      "2 integer 2 non-integer indexes result unorder with pairs",
      kv_concat(
          {x = 3, y = "2", z = 1, aaa = "!?#$%^&*()_+|~/"},
          "=",
          ",",
          ordered_pairs
        ),
      "aaa=!?#$%^&*()_+|~/,x=3,y=2,z=1"
    )

  ensure_strvariant(
      "2 integer 2 non-integer indexes result unorder with pairs",
      kv_concat({ x = 3, y = "2", 1, "!?#$%^&*()_+|~/" }, "=", ",", pairs),
      {
        "1=1,2=!?#$%^&*()_+|~/,y=2,x=3";
        "1=1,2=!?#$%^&*()_+|~/,x=3,y=2";
      }
    )
  ensure_strvariant(
      "2 integer 2 non-integer indexes result unorder with no function",
      kv_concat({ x = 3, y = "2", 1, "!?#$%^&*()_+|~/" }, "=", ","),
      {
        "1=1,2=!?#$%^&*()_+|~/,y=2,x=3";
        "1=1,2=!?#$%^&*()_+|~/,x=3,y=2";
      }
    )
  -- Feature: nested tables is not allowed
  ensure_fails_with_substring(
      "nested tables are invalid",
      function()
        kv_concat({ 3, "2", { 1, "!?#$%^&*()_+|~/" } }, " ", ",", pairs)
      end,
      "invalid value"
    )
end)

--------------------------------------------------------------------------------

test:tests_for "escape_for_json"

test "escape_for_json-basic" (function()
  ensure_strequals(
      "letters and slash",
      escape_for_json("abcXYZs/n"),
      "\"abcXYZs/n\""
    )
  ensure_strequals("slash and backslash", escape_for_json("s/\n"), "\"s/\\n\"")
  ensure_strequals(
      "escape sequences",
      escape_for_json("\"s/\n\b\fu\rper\t\v"),
      "\"\\\"s/\\n\\b\\fu\\rper\\t\\v\""
    )
  ensure_strequals("double backslash", escape_for_json(" \\ "), "\" \\\\ \"")
  ensure_strequals("slash num", escape_for_json(" /007 "), "\" /007 \"")
end)

test "escape_for_json-injection" (function()
  ensure_strequals(
      "common json injection",
      escape_for_json(
          "';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharC" ..
          "ode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//\";alert" ..
          "(String.fromCharCode(88,83,83))//--></SCRIPT>\">'><SCRIPT>alert(S" ..
          "tring.fromCharCode(88,83,83))</SCRIPT>"
        ),
      "\"';alert(String.fromCharCode(88,83,83))//';alert(String.fromCharCode" ..
      "(88,83,83))//\\\";alert(String.fromCharCode(88,83,83))//\\\";alert(St" ..
      "ring.fromCharCode(88,83,83))//--></SCRIPT>\\\">'><SCRIPT>alert(String" ..
      ".fromCharCode(88,83,83))</SCRIPT>\""
    )
end)

--------------------------------------------------------------------------------

test:test_for "url_encode" (function()
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

test:test_for "integer_to_string_with_base" (function()
  ensure_equals("simple", integer_to_string_with_base(10, 26), "A")
  ensure_equals("empty base", integer_to_string_with_base(10), "10")
  ensure_equals("test with negative numbers", integer_to_string_with_base(-11, 26), "-B")
  ensure_equals("test with zero and empty base", integer_to_string_with_base(0), "0")
  ensure_equals("test with zero and non-empty base", integer_to_string_with_base(0, 15), "0")

  -- NOTE: integer_to_string_with_base(-0) can produce '0' or '-0', depending on
  -- previous code. See:
  -- http://thread.gmane.org/gmane.comp.lang.lua.general/90837/focus=90838
  -- http://article.gmane.org/gmane.comp.lang.lua.general/12950
  ensure(
      "test with negative zero and empty base",
      integer_to_string_with_base(-0) == "0" or integer_to_string_with_base(-0) == "-0"
    )

  local n = 136
  local base = 36
  local str = integer_to_string_with_base(n, base)
  ensure_equals("test with tonumber", tonumber(str, base), n)

  ensure_fails_with_substring("test with empty params", integer_to_string_with_base, "n must be a number")
  ensure_fails_with_substring(
      "test with string value of base",
      function()
        integer_to_string_with_base(10, "asd")
      end,
      "base must be a number"
    )
  ensure_fails_with_substring(
      "test with negative base",
      function()
        integer_to_string_with_base(10, -10)
      end,
      "base out of range"
    )
  ensure_fails_with_substring(
      "test on nan",
      function()
        integer_to_string_with_base(0/0)
      end,
      "n is nan"
    )
  ensure_fails_with_substring(
      "test on +inf",
      function()
        integer_to_string_with_base(1/0)
      end,
      "n is inf"
    )
  ensure_fails_with_substring(
      "test on -inf",
      function()
        integer_to_string_with_base(-1/0)
      end,
      "n is inf"
    )

  ensure_fails_with_substring(
      "test on -inf",
      function()
        integer_to_string_with_base(-1/0)
      end,
      "n is inf"
    )
end)

test:test_for "cut_with_ellipsis" (function()

  local test_string = "test long string"

  ensure_equals(
      "test with string with correct max length",
      cut_with_ellipsis(test_string, #test_string),
      test_string
    )

  ensure_equals(
      "test with string length - 1",
      cut_with_ellipsis(test_string, #test_string - 1),
      "test long st..."
    )

  ensure_equals(
      "test with string length - 2",
      cut_with_ellipsis(test_string, #test_string - 2),
      "test long s..."
    )

  ensure_equals(
      "test with string length - 3",
      cut_with_ellipsis(test_string, #test_string - 3),
      "test long ..."
    )

  ensure_equals(
      "test with string with excess max length",
      cut_with_ellipsis(test_string, #test_string + 50),
      test_string
    )

  ensure_equals(
      "test with string with default max length",
      cut_with_ellipsis(test_string),
      test_string
    )

  ensure_equals(
      "test with cutting long string",
      cut_with_ellipsis(test_string, 12),
      "test long..."
    )

  ensure_equals(
      "test with max length = 1",
      cut_with_ellipsis(test_string, 1),
      "t"
    )

  ensure_equals(
      "test with max length = 2",
      cut_with_ellipsis(test_string, 2),
      "te"
    )

  ensure_equals(
      "test with max length = 3",
      cut_with_ellipsis(test_string, 3),
      "tes"
    )

  ensure_equals(
      "test with max length = 4",
      cut_with_ellipsis(test_string, 4),
      "t..."
    )

  ensure_equals(
      "test with empty string",
      cut_with_ellipsis(""),
      ""
    )

  ensure_fails_with_substring(
      "test with non-positive required string length",
      function()
        cut_with_ellipsis(test_string, 0)
      end,
      "required string length must be positive"
    )
end)

--------------------------------------------------------------------------------

test:test_for "number_to_string" (function()
  ensure_strequals("inf", number_to_string(1/0), "1/0")
  ensure_strequals("-inf", number_to_string(-1/0), "-1/0")
  ensure_strequals("nan", number_to_string(0/0), "0/0")
end)

test:test_for "serialize_number" (function()
  ensure_strequals("inf", serialize_number( 1/0), "1/0")
  ensure_strequals("-inf", serialize_number(-1/0), "-1/0")
  ensure_strequals("nan", serialize_number(0/0), "0/0")
  ensure_strequals("123", serialize_number(123), "123")

  local pi_15 = loadstring("return " .. ("%.15g"):format(math_pi))()
  local pi_16 = loadstring("return " .. ("%.16g"):format(math_pi))()
  local pi_17 = loadstring("return " .. serialize_number(math_pi))()
  local pi_18 = loadstring("return " .. ("%.18g"):format(math_pi))()
  local pi_55 = loadstring("return " .. ("%.55g"):format(math_pi))()
  ensure(
      "serialize pi by %.15g",
      pi_15 ~= math.pi
    )
  ensure(
      "serialize pi by %.16g",
      pi_16 == math.pi
    )
  ensure(
      "serialize pi by %.17g",
      pi_17 == math.pi
    )
  ensure(
      "serialize pi by %.18g",
      pi_18 == math.pi
    )
  ensure(
      "serialize pi by %.55g",
      pi_55 == math.pi
    )

  local one_third_15 = loadstring("return " .. ("%.15g"):format(1/3))()
  local one_third_16 = loadstring("return " .. ("%.16g"):format(1/3))()
  local one_third_17 = loadstring("return " .. serialize_number(1/3))()
  local one_third_18 = loadstring("return " .. ("%.18g"):format(1/3))()
  local one_third_55 = loadstring("return " .. ("%.55g"):format(1/3))()
  ensure(
      "serialize 1/3 by %.15g",
      one_third_15 ~= 1/3
    )
  ensure(
      "serialize 1/3 by %.16g",
      one_third_16 == 1/3
    )
  ensure(
      "serialize 1/3 by %.17g",
      one_third_17 == 1/3
    )
  ensure(
      "serialize 1/3 by %.18g",
      one_third_18 == 1/3
    )
  ensure(
      "serialize 1/3 by %.55g",
      one_third_55 == 1/3
    )
    end)

--------------------------------------------------------------------------------

test:tests_for 'get_escaped_chars_in_ranges'

test:test "get_escaped_chars_in_ranges-basic" (function()
  -- Invalid tests (argument errors).
  ensure_fails_with_substring(
      "missed argument",
      get_escaped_chars_in_ranges,
      "argument must be a table"
    )
  ensure_fails_with_substring(
      "invalid type argument",
      function()
        get_escaped_chars_in_ranges("asd")
      end,
      "argument must be a table"
    )
  ensure_fails_with_substring(
      "one element in table",
      function()
        get_escaped_chars_in_ranges({ "asd" })
      end,
      "argument must have even number of elements"
    )
  ensure_fails_with_substring(
      "three elements in table",
      function()
        get_escaped_chars_in_ranges({ "1", "2", "3" })
      end,
      "argument must have even number of elements"
    )

  -- Valid tests:
  -- Chars range boundaries
  ensure_strequals("equal str", get_escaped_chars_in_ranges({ "e", "e" }), "%e")
  ensure_strequals("equal int", get_escaped_chars_in_ranges({ "6", "6" }), "%6")
  ensure_strequals(
      "2 integers in string",
      get_escaped_chars_in_ranges({ "7", "8" }),
      "%7%8"
    )
  ensure_strequals(
      "4 ints in string",
      get_escaped_chars_in_ranges({ "7", "8", "45", "33" }),
      "%7%8"
    )
  ensure_strequals(
      "2-digit int in string",
      get_escaped_chars_in_ranges({ "66", "77", "45", "33" }),
      "%6%7"
    )
  ensure_strequals(
      "range in int in string",
      get_escaped_chars_in_ranges({ "22", "77", "4", "254" }),
      "%2%3%4%5%6%7"
    )
  ensure_strequals(
      "max range in int in string",
      get_escaped_chars_in_ranges({ "0", "9", "A", "Z" }),
      "%0%1%2%3%4%5%6%7%8%9%A%B%C%D%E%F%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%U%V%W%X%Y%Z"
    )
  ensure_strequals(
      "char range",
      get_escaped_chars_in_ranges({ "a", "d", "4", "25" }),
      "%a%b%c%d"
    )
  ensure_strequals(
      "char and int in str range",
      get_escaped_chars_in_ranges({ "a", "d", "4", "9" }),
      "%a%b%c%d%4%5%6%7%8%9"
    )
  ensure_strequals(
      "from 0 to A",
      get_escaped_chars_in_ranges({ "0", "A" }),
      "%0%1%2%3%4%5%6%7%8%9%:%;%<%=%>%?%@%A"
    )
  ensure_strequals(
      "from space to ~",
      get_escaped_chars_in_ranges({ " ", "~" }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%;%<%=%>%?%@%A" ..
      "%B%C%D%E%F%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%U%V%W%X%Y%Z%[%\\%]%^%_%`%a%b%c" ..
      "%d%e%f%g%h%i%j%k%l%m%n%o%p%q%r%s%t%u%v%w%x%y%z%{%|%}%~"
    )

  -- Integers range boundaries
  ensure_strequals(
      "integer range",
      get_escaped_chars_in_ranges({ 32, 58 }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:"
    )
  ensure_strequals(
      "from ch(32) to ch(32)",
      get_escaped_chars_in_ranges({ 32, 126 }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%;%<%=%>%?%@%A" ..
      "%B%C%D%E%F%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%U%V%W%X%Y%Z%[%\\%]%^%_%`%a%b%c" ..
      "%d%e%f%g%h%i%j%k%l%m%n%o%p%q%r%s%t%u%v%w%x%y%z%{%|%}%~"
    )

  -- Mixed range boundaries
  ensure_strequals(
      "all mixed up",
      get_escaped_chars_in_ranges({ "0", 50 }),
      "%0%1%2"
    )
  ensure_strequals(
      "from ch(32) to ~",
      get_escaped_chars_in_ranges({ 32, "~" }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%;%<%=%>%?%@%A" ..
      "%B%C%D%E%F%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%U%V%W%X%Y%Z%[%\\%]%^%_%`%a%b%c" ..
      "%d%e%f%g%h%i%j%k%l%m%n%o%p%q%r%s%t%u%v%w%x%y%z%{%|%}%~"
    )
  ensure_strequals(
      "from space to ch(126)",
      get_escaped_chars_in_ranges({ " ", 126 }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%;%<%=%>%?%@%A" ..
      "%B%C%D%E%F%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%U%V%W%X%Y%Z%[%\\%]%^%_%`%a%b%c" ..
      "%d%e%f%g%h%i%j%k%l%m%n%o%p%q%r%s%t%u%v%w%x%y%z%{%|%}%~"
    )
  ensure_strequals(
      "integer range and letters",
      get_escaped_chars_in_ranges({ 32, 58, "a", "h" }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%a%b%c%d%e%f%g%h"
    )
  ensure_strequals(
      "all mixed up",
      get_escaped_chars_in_ranges({ 32, 58, "a", "h", 34, 38, "0", 50 }),
      "% %!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%0%1%2%3%4%5%6%7%8%9%:%a%b%c%d%e%f%g" ..
      "%h%\"%#%$%%%&%0%1%2"
    )
end)

--------------------------------------------------------------------------------

test:test_for("tjson_simple"):BROKEN_IF(not newproxy) (function()
  -- Helpers
  local coroutine_create = coroutine.create
  local ensure_tjson_fails = function(msg, data, error_msg)
    ensure_fails_with_substring(
        msg,
        function() tjson_simple(data) end,
        error_msg
      )
  end
  local ensure_tjson_unsupported_type = function(data)
    ensure_tjson_fails(
        "unsupported type check",
        data,
        "tjson_simple: value type `" .. type(data) .. "' not supported"
      )
  end

  -- Single values: number, string, boolean
  ensure_strequals('single integer (positive)', tjson_simple(123), '123')
  ensure_strequals('single integer (negative)', tjson_simple(-123), '-123')
  ensure_strequals('single float', tjson_simple(123.123), '123.123')
  ensure_strequals('single string', tjson_simple('Just text'), '"Just text"')
  ensure_strequals('single boolean (true)', tjson_simple(true), 'true')
  ensure_strequals('single boolean (false)', tjson_simple(false), 'false')

  -- Unsupported types: nil, function, thread, userdata
  ensure_tjson_unsupported_type(nil)
  ensure_tjson_unsupported_type(function() end)
  ensure_tjson_unsupported_type(coroutine_create(function() end))
  ensure_tjson_unsupported_type(newproxy())

  -- Unsupported values: NaN, +Inf, -Inf
  ensure_tjson_fails(
      'unsupported value', 1/0, "tjson_simple: `Inf' value not supported"
    )
  ensure_tjson_fails(
      'unsupported value', -1/0, "tjson_simple: `Inf' value not supported"
    )
  ensure_tjson_fails(
      'unsupported value', 0/0, "tjson_simple: `NaN' value not supported"
    )

  -- Tables
  ensure_strequals(
      'table to array',
      tjson_simple({1, -1, 123.123, 'abc', true, false, { }}),
      '[1,-1,123.123,"abc",true,false,[]]'
    )

  ensure_strlist(
      'table to object',
      tjson_simple(
        {a = 1, b = -1, c = 123.123, d = 'abc', e = true, f = false, j = {1}}
      ),
      '{',
      {
        '"a":1';
        '"c":123.123';
        '"b":-1';
        '"e":true';
        '"d":"abc"';
        '"j":[1]';
        '"f":false';
      },
      ',',
      '}'
    )

  ensure_strequals(
      'empty table to object with tisarray_not',
      tjson_simple(tisarray_not({ })),
      '{}'
    )
  ensure_strequals('empty table', tjson_simple({ }), '[]')
  ensure_strequals('empty tables', tjson_simple({ { }, { } }), '[[],[]]')

  -- Exceptions
  local self_reference_tbl = { }
  self_reference_tbl[1] = self_reference_tbl
  ensure_tjson_fails(
      'self reference',
      self_reference_tbl,
      "tjson_simple: can't handle self-references"
    )

  local mixed_keys_tbl = { "a", "b" }
  mixed_keys_tbl["c"] = "d"
  ensure_tjson_fails(
      'mixed keys',
      mixed_keys_tbl,
      "tjson_simple: non-string keys are not supported"
    )

  local non_string_key_tbl = { }
  non_string_key_tbl[1.23] = 1
  ensure_tjson_fails(
      'non string keys',
      non_string_key_tbl,
      "tjson_simple: non-string keys are not supported"
    )
end)
