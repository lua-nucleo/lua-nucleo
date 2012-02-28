--------------------------------------------------------------------------------
-- 0380-scoped_cat_tree_manager.lua: tests for stack manager with factory
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

local make_scoped_cat_tree_manager,
      exports
      = import 'lua-nucleo/scoped_cat_tree_manager.lua'
      {
        'make_scoped_cat_tree_manager'
      }

--------------------------------------------------------------------------------

local test = make_suite("scoped_cat_tree_manager", exports)

--------------------------------------------------------------------------------

test:factory("make_scoped_cat_tree_manager", make_scoped_cat_tree_manager)

--------------------------------------------------------------------------------

test:TODO "test make_scoped_cat_tree_manager"

--------------------------------------------------------------------------------

assert(test:run())
