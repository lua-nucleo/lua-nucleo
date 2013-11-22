--------------------------------------------------------------------------------
-- 0600-key-value-store-simple.lua: tests for simple key-value store
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

local make_simple_key_value_store
      = import "lua-nucleo/key_value_store/key_value_store_simple.lua"
      {
        "make_simple_key_value_store"
      }

---------------------------------------------------------------------------

-- TODO: write tests
--       https://redmine-tmp.iphonestudio.ru/issues/3665

test:TODO "write tests"
