--------------------------------------------------------------------------------
-- 0610-key-value-store-ophash.lua: tests for ophash key-value store
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile("test/test-lib/init/strict.lua"))(...)

---------------------------------------------------------------------------

local test = make_suite("key-value-store-ophash")

---------------------------------------------------------------------------

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_returns,
      ensure_fails_with_substring
      = import "lua-nucleo/ensure.lua"
      {
        "ensure",
        "ensure_equals",
        "ensure_strequals",
        "ensure_tequals",
        "ensure_returns",
        "ensure_fails_with_substring"
      }

---------------------------------------------------------------------------

local make_ophash_key_value_store
      = import "lua-nucleo/key_value_store/key_value_store_ophash.lua"
      {
        "make_ophash_key_value_store"
      }

---------------------------------------------------------------------------

-- TODO: write tests
--       https://redmine-tmp.iphonestudio.ru/issues/3665

test:TODO "write tests"
