-- 0340-import_as_require.lua: tests for import-as-require
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

assert(
    loadfile('test/test-lib/init/no-suite-no-import.lua')
  )(...)

--------------------------------------------------------------------------------

package.path = './?' .. package.path

-- Note global!
import = require('lua-nucleo.import_as_require').import

local res, err = pcall(function()
  -- TODO: Keep up-to-date somehow automatically.
  local files =
  {
    'lua-nucleo/algorithm.lua';
    'lua-nucleo/args.lua';
    'lua-nucleo/assert.lua';
    'lua-nucleo/checker.lua';
    'lua-nucleo/coro.lua';
    'lua-nucleo/deque.lua';
    'lua-nucleo/ensure.lua';
    'lua-nucleo/factory.lua';
    'lua-nucleo/functional.lua';
    -- 'lua-nucleo/import.lua';  -- Has side-effects, skipping
    -- 'lua-nucleo/import_as_require.lua'; -- Has side-effects, skipping
    'lua-nucleo/language.lua';
    'lua-nucleo/log.lua';
    'lua-nucleo/math.lua';
    'lua-nucleo/misc.lua';
    'lua-nucleo/prettifier.lua';
    'lua-nucleo/priority_queue.lua';
    'lua-nucleo/random.lua';
    'lua-nucleo/sandbox.lua';
    -- 'lua-nucleo/strict.lua'; -- Has side-effects, skipping
    'lua-nucleo/string.lua';
    -- 'lua-nucleo/suite.lua';  -- Has side-effects, skipping
    'lua-nucleo/table-utils.lua';
    'lua-nucleo/table.lua';
    'lua-nucleo/tdeepequals.lua';
    'lua-nucleo/timed_queue.lua';
    'lua-nucleo/timestamp.lua';
    'lua-nucleo/tpretty.lua';
    'lua-nucleo/tserialize.lua';
    'lua-nucleo/tstr.lua';
    'lua-nucleo/type.lua';
    'lua-nucleo/typeassert.lua';
    'lua-nucleo/util/anim/interpolator.lua';
  }

  for i = 1, #files do
    import(files[i])
  end
end)

import = nil -- Avoiding side-effects

assert(res, err)
