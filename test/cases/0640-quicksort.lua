--------------------------------------------------------------------------------
-- 0640-quicksort.lua: tests for quicksort implementation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

local ensure_equals,
      ensure_is,
      ensure_tdeepequals
      = import "lua-nucleo/ensure.lua"
      {
        "ensure_equals",
        "ensure_is",
        "ensure_tdeepequals"
      }

local quicksort,
      quicksort_exports
      = import "lua-nucleo/quicksort.lua"
      {
        "quicksort"
      }

--------------------------------------------------------------------------------

local hash_k_less_than = function(lhs, rhs)
  return lhs.k < rhs.k
end

local hash_v_less_than = function(lhs, rhs)
  return lhs.v < rhs.v
end

local check = function(message, array, expected, ...)
  ensure_tdeepequals(message, quicksort(array, ...), expected)
end

--------------------------------------------------------------------------------

local test = make_suite("quicksort", quicksort_exports)

--------------------------------------------------------------------------------

test:tests_for "quicksort"

test "empty-array" (function()
  check("empty array sorted ok", { }, { })
end)

test "single-array" (function()
  check("array of single element sorted ok", { 999 }, { 999 })
end)

test "int-array" (function()
  check(
      "array of integers sorted ok",
      { 0, 1, 10, -3, 3, -10, -1 },
      { -10, -3, -1, 0, 1, 3, 10 }
    )
end)

test "double-array" (function()
  check(
      "array of doubles sorted ok",
      { 0.2, 1.2, 10.3, -3.1, -3.11, -10.8, -1.21 },
      { -10.8, -3.11, -3.1, -1.21, 0.2, 1.2, 10.3 }
    )
end)

test "array-explicit-slice" (function()
  check(
      "slice [0..6] sorted ok",
      { [0] = 0, 1, 10, -3, 3, -10, -1 },
      { [0] = -10, -3, -1, 0, 1, 3, 10 },
      nil,
      0,
      6
    )
  check(
      "slice [-1..5] sorted ok",
      { [-1] = 0, [0] = 1, 10, -3, 3, -10, -1 },
      { [-1] = -10, [0] = -3, -1, 0, 1, 3, 10 },
      nil,
      -1,
      5
    )
end)

test "array-of-hashes" (function()
  check(
      "array of hashes sorted ok by hash key",
      {
        { k = 2, v = "a" };
        { k = 0, v = "b" };
        { k = 1, v = "aa" };
      },
      {
        { k = 0, v = "b" };
        { k = 1, v = "aa" };
        { k = 2, v = "a" };
      },
      hash_k_less_than
    )
  check(
      "array of hashes sorted ok by hash value",
      {
        { k = 2, v = "a" };
        { k = 0, v = "b" };
        { k = 1, v = "aa" };
      },
      {
        { k = 2, v = "a" };
        { k = 1, v = "aa" };
        { k = 0, v = "b" };
      },
      hash_v_less_than
    )
end)

test "table.sort-equivalence" (function()
  local t1, t2 = { }, { }
  math.randomseed(os.time())
  for i = 1, 4096 do
    t1[i] = math.random(-100, 100)
    t2[i] = t1[i]
  end
  table.sort(t1)
  check("quicksort sorts as table.sort does", t2, t1)
end)

--------------------------------------------------------------------------------

local create_almost_ordered_table = function(n)
  local t =
    {
      { k = 2, v = "a" };
      { k = 0, v = "b" };
    }
  for i = 2, n - 1 do
    t[#t + 1] = { k = 1, v = i }
  end
  return t
end

local ensure_order_of_equal_elements = function(t)
  ensure_equals("first element's k is 0", t[1].k, 0)
  ensure_equals("last element's k is 2", t[#t].k, 2)
  for i = 2, #t - 1 do
    ensure_equals("middle elements's v are in input order", t[i].v, i)
  end
end

local check_sort_stability = function(n)
  ensure_order_of_equal_elements(
      quicksort(create_almost_ordered_table(n), hash_k_less_than)
    )
end

test "is-stable-if-nelem-not-greater-insertion-thresold" (function()
  check_sort_stability(1)
  check_sort_stability(16)
end)

-- NB: express marked broken, to ensure quicksort instability
test:BROKEN "is-stable-beyond-insertion-thresold" (function()
  check_sort_stability(128)
  check_sort_stability(2048)
end)
