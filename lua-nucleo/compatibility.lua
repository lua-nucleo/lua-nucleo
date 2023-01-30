--------------------------------------------------------------------------------
--- Various compatibility utilities
-- @module lua-nucleo.compatibility
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- Inspired by setfenv from MIT-licensed etlua
-- https://github.com/leafo/etlua
local setfenv = setfenv or function(fn, env)
  local i = 1
  while true do
    local name = debug.getupvalue(fn, i)
    if name == "_ENV" then
      debug.upvaluejoin(fn, i, (function()
        return env
      end), 1)
      break
    elseif not name then
      break
    end

    i = i + 1
  end

  return fn
end

return {
  setfenv = setfenv;
}
