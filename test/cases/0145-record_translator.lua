--------------------------------------------------------------------------------
-- 0145-record_translator.lua: tests for record translator
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local translator,
      captures,
      mutators,
      record_translator_exports
      = import 'lua-nucleo/record_translator.lua'
      {
        'translator',
        'captures',
        'mutators'
      }

--------------------------------------------------------------------------------

local test = make_suite("record_translator", record_translator_exports)

--------------------------------------------------------------------------------

test:UNTESTED 'translator'
test:UNTESTED 'captures'
test:UNTESTED 'mutators'
