--------------------------------------------------------------------------------
--- Replacements of legacy Lua functions
-- @module lua-nucleo.legacy
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

if declare then declare 'loadstring' end
local loadstring = loadstring or load

if declare then declare 'newproxy' end
local newproxy = newproxy or require 'lua-nucleo.newproxy'

if declare then declare 'unpack' end
local unpack = unpack or table.unpack

if declare then declare 'setfenv' end
local setfenv = setfenv or function(chunk, env)
  return load(chunk, nil, nil, env)
end

return
{
  loadstring = loadstring;
  newproxy = newproxy;
  unpack = unpack;
  setfenv = setfenv;
}
