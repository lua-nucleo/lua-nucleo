-- 0360-stack_with_factory.lua: tests for stack manager with factory
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

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

local make_stack_with_factory,
      stack_with_factory_exports
      = import 'lua-nucleo/stack_with_factory.lua'
      {
        'make_stack_with_factory'
      }

--------------------------------------------------------------------------------

local test = make_suite("stack_with_factory", stack_with_factory_exports)

--------------------------------------------------------------------------------

test:factory("make_stack_with_factory", make_stack_with_factory)

--------------------------------------------------------------------------------

test:TODO "test make_stack_with_factory"

--------------------------------------------------------------------------------

assert(test:run())
