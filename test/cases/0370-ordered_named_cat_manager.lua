--------------------------------------------------------------------------------
-- 0370-ordered_named_cat_manager.lua: tests for ordered named cat manager
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local make_ordered_named_cat_manager,
      exports
      = import 'lua-nucleo/ordered_named_cat_manager.lua'
      {
        'make_ordered_named_cat_manager'
      }

--------------------------------------------------------------------------------

local test = make_suite("ordered_named_cat_manager", exports)

--------------------------------------------------------------------------------

test:factory("make_ordered_named_cat_manager", make_ordered_named_cat_manager)

--------------------------------------------------------------------------------

test:TODO "test make_ordered_named_cat_manager"

--------------------------------------------------------------------------------

assert(test:run())
