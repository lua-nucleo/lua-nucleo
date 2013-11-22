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

local make_sophisticated_key_value_store
      = import "lua-nucleo/key_value_store/key_value_store_sophisticated.lua"
      {
        "make_sophisticated_key_value_store"
      }

---------------------------------------------------------------------------

-- TODO: write tests
--       https://redmine-tmp.iphonestudio.ru/issues/3665

test:TODO "write tests"
