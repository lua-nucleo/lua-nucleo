-- all-tests.lua: the list of all tests in the library
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

return
{
  'suite';
  'suite-full';
  'strict';
  'import';
  'import-base_path';
  --
  'tserialize-basic';
  'tserialize-recursive';
  'tserialize-metatables';
  'tserialize-autogen';
  --
  'tdeepequals-basic-types';
  'tdeepequals-basic-tables';
  'tdeepequals-recursive';
  'tdeepequals-userdata-functions-threads';
  'tdeepequals-autogen';
  --
  'table-utils';
  'table';
  --
  'coro';
  'functional';
  'factory';
  'random';
  'algorithm';
  'math';
  'string';
  'args';
  'misc';
  'type';
  'typeassert';
  'checker';
  'assert';
  'log';
  'priority_queue';
  'timed_queue';
  'deque';
  --
  'util/anim/interpolator';
}
