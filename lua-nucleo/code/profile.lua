--------------------------------------------------------------------------------
-- profile.lua: lua-nucleo exports profile
--------------------------------------------------------------------------------

local tset = import 'lua-nucleo/table-utils.lua' { 'tset' }

--------------------------------------------------------------------------------

local PROFILE = { }

--------------------------------------------------------------------------------

PROFILE.skip = setmetatable(tset
{
  "lua-nucleo/import.lua";  -- Too low-level
  "lua-nucleo/import_as_require.lua";  -- Too low-level
  "lua-nucleo/strict.lua";  -- Too low-level
  "lua-nucleo/suite.lua";   -- Too low-level
  "lua-nucleo/table.lua";   -- Contains aliases only, too ambiguous
  "lua-nucleo/module.lua";  -- Too low-level
  "lua-nucleo/pcall.lua";   -- Only for manual use
}, {
  __index = function(t, k)
    -- Excluding files outside of lua-nucleo/ and inside lua-nucleo/code
    local v = (not k:match("^lua%-nucleo/")) or k:match("^lua%-nucleo/code/")
    t[k] = v
    return v
  end;
})

--------------------------------------------------------------------------------

return PROFILE
