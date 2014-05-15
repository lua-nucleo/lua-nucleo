--------------------------------------------------------------------------------
-- 0620-key-value-store-simple.lua: tests for simple key-value store
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

---------------------------------------------------------------------------

local test = make_suite("key-value-store-simple")

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

local make_simple_key_value_store
      = import "lua-nucleo/key_value_store/key_value_store_simple.lua"
      {
        "make_simple_key_value_store"
      }

---------------------------------------------------------------------------

local create_storage = function(filename)
  -- storage
  local less_than = function(lhs, rhs)
    return lhs < rhs
  end
  local storage = make_simple_key_value_store(208, less_than)
  -- fill
  for k in io.lines(filename) do
    storage:add(k, k)
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

---------------------------------------------------------------------------

test "returns_what_has_taken" (function()

  local orig = read_original("test/data/key_value_store/orig.tsv")
  local orig_kv = { }
  for i = 1, #orig do
    orig_kv[#orig_kv + 1] = {orig[i], orig[i]}
  end

  local storage = create_storage("test/data/key_value_store/orig.tsv")
  ensure_tequals(
      "storage is sane about keys",
      dump_storage_keys(storage),
      orig
    )
  ensure_tequals(
      "storage is sane about values",
      dump_storage_values(storage),
      orig
    )
  ensure_tdeepequals(
      "storage is sane about key/values",
      dump_storage_pairs(storage),
      orig_kv
    )

end)

---------------------------------------------------------------------------

test "sorts_ok" (function()

  local storage = create_storage("test/data/key_value_store/orig.tsv")
  storage:sort()
  ensure_tequals(
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
      #storage.set_,
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
