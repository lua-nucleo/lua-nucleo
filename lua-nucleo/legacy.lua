--------------------------------------------------------------------------------
--- Replacements of legacy Lua functions
-- @module lua-nucleo.legacy
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local loadstring = loadstring or function(code, chunkname)
  return load(code, chunkname, 't')
end

return
{
  loadstring = loadstring;
}
