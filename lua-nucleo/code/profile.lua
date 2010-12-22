--------------------------------------------------------------------------------
-- profile.lua: lua-nucleo exports profile
--------------------------------------------------------------------------------

local tset = import 'lua-nucleo/table-utils.lua' { 'tset' }

--------------------------------------------------------------------------------

local PROFILE = { }

--------------------------------------------------------------------------------

PROFILE.skip = tset
{
  "lua-nucleo/import.lua";  -- Too low-level
  "lua-nucleo/import_as_require.lua";  -- Too low-level
  "lua-nucleo/strict.lua";  -- Too low-level
  "lua-nucleo/suite.lua";   -- Too low-level
  "lua-nucleo/table.lua";   -- Contains aliases only, too ambiguous
  "lua-nucleo/module.lua";  -- Too low-level
}

--------------------------------------------------------------------------------

return PROFILE
