--------------------------------------------------------------------------------
-- 0630-key-value-store-sophisticated.lua: tests for sophisticated store
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

---------------------------------------------------------------------------

local test = make_suite("key-value-store-sophisticated")

---------------------------------------------------------------------------

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_tdeepequals,
      ensure_returns,
      ensure_fails_with_substring
      = import "lua-nucleo/ensure.lua"
      {
        "ensure",
        "ensure_equals",
        "ensure_strequals",
        "ensure_tequals",
        "ensure_tdeepequals",
        "ensure_returns",
        "ensure_fails_with_substring"
      }

---------------------------------------------------------------------------

local make_sophisticated_key_value_store
      = import "lua-nucleo/key_value_store/key_value_store_sophisticated.lua"
      {
        "make_sophisticated_key_value_store"
      }

---------------------------------------------------------------------------

local create_storage = function(filename)
  -- storage
  local less_than = function(lhs, rhs)
    return lhs < rhs
  end
  local hash_less_than = function(lhs, rhs)
    return lhs < rhs
  end
  local storage = make_sophisticated_key_value_store(
      208,
      less_than,
      hash_less_than,
      16
    )
  -- fill
  -- NB: prefix hash should be used
  for k in io.lines(filename) do
    storage:add(k, k, k:sub(1, 1))
  end
  return storage
end

local dump_storage_keys = function(storage)
  local r = { }
  storage:for_each_key(function(k)
    r[#r + 1] = k
  end)
  return r
end

local dump_storage_values = function(storage)
  local r = { }
  storage:for_each_value(function(v)
    r[#r + 1] = v
  end)
  return r
end

local dump_storage_pairs = function(storage)
  local r = { }
  storage:for_each_keyvalue(function(k, v)
    r[#r + 1] = {k, v}
  end)
  return r
end

local read_original = function(filename)
  local r = { }
  for k in io.lines(filename) do
    r[#r + 1] = k
  end
  return r
end

local ensure_tables_congruent = function(msg, actual, expected)
  local function aggregate(t)
    local r = { }
    for i = 1, #t do
      r[t[i]] = (r[t[i]] or 0) + (t[i].values and #t[i].values or 1)
    end
    return r
  end
  ensure_tdeepequals(msg, aggregate(actual), aggregate(expected))
end

local ensure_lists_congruent = function(msg, actual, expected)
  local list_to_hash = function(t)
    local r = { }
    for i = 1, #t do
      r[t[i]] = 1
    end
    return r
  end
  ensure_tdeepequals(msg, list_to_hash(actual), list_to_hash(expected))
end

---------------------------------------------------------------------------

test "returns_what_has_taken" (function()

  local orig = read_original("test/data/key_value_store/orig.tsv")
  local orig_kv = { }
  for i = 1, #orig do
    orig_kv[#orig_kv + 1] = {orig[i], orig[i]}
  end

  local storage = create_storage("test/data/key_value_store/orig.tsv")
  ensure_lists_congruent(
      "storage is sane about keys",
      dump_storage_keys(storage),
      orig
    )
  ensure_tables_congruent(
      "storage is sane about values",
      dump_storage_values(storage),
      orig
    )
  ensure_tables_congruent(
      "storage is sane about key/values",
      dump_storage_pairs(storage),
      orig_kv
    )

end)

---------------------------------------------------------------------------

test "sorts_ok" (function()

  local storage = create_storage("test/data/key_value_store/orig.tsv")
  storage:sort()
  ensure_lists_congruent(
      "storage is sane about sorted keys",
      dump_storage_keys(storage),
      read_original("test/data/key_value_store/orig-sorted.tsv")
    )
  ensure_tequals(
      "storage is sane about sorted values",
      dump_storage_values(storage),
      read_original("test/data/key_value_store/orig-sorted.tsv")
    )

end)

---------------------------------------------------------------------------

test "methods_work" (function()

  -- fill
  local storage = create_storage("test/data/key_value_store/orig.tsv")
  ensure_equals(
      "storage keeps 208 items",
      storage.num_values_,
      208
    )
  -- has room?
  ensure_equals(
      "storage is full",
      storage:can_add(),
      false
    )
  -- empty?
  ensure_equals(
      "storage is not empty",
      storage:empty(),
      false
    )

  -- clear
  storage:clear()
  -- has room?
  ensure_equals(
      "storage is not full after cleared",
      storage:can_add(),
      true
    )
  -- empty?
  ensure_equals(
      "storage is empty after cleared",
      storage:empty(),
      true
    )

end)

---------------------------------------------------------------------------
