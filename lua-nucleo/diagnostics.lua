--------------------------------------------------------------------------------
--- Various code diagnostics utilities
-- @module lua-nucleo.diagnostics
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local debug_getinfo = debug.getinfo

--------------------------------------------------------------------------------

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

--------------------------------------------------------------------------------

--- Captures location in source code at given call stack level.
--
-- Returns `nil` if requested call stack `level` is larger than
-- number of functions currently in the call stack.
-- @int[opt=1] level call stack level
-- @treturn SourceLocation Source code location.
-- @see debug.getinfo
local capture_source_location = function(
    level
  )
  level = level or 1

  arguments("number", level)

  local info = debug_getinfo(level + 1, "Sl")
  if not info then
    return nil -- level is too large
  end

  --- Source code location
  -- @table SourceLocation
  -- @string source exact source filename
  -- @string file short source filename
  -- @int line line number in the source file
  return
  {
    source = info.source;
    file = info.short_src;
    line = info.currentline;
  }
end

--------------------------------------------------------------------------------

return
{
  capture_source_location = capture_source_location;
}
