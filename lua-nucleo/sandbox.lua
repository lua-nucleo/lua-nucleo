-- sandbox.lua: sandbox-related stuff
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Move more code here

--------------------------------------------------------------------------------

local setmetatable, setfenv, xpcall, loadstring
    = setmetatable, setfenv, xpcall, loadstring

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

--------------------------------------------------------------------------------

-- Automatically creates subtables for a.b.c = 42 notation.
local make_config_environment
do
  local mt
  mt =
  {
    __metatable = "config_environment";
    __index = function(t, k)
      local v = setmetatable({ }, mt)
      t[k] = v
      return v
    end;
  }

  make_config_environment = function(t)
    return setmetatable(t or { }, mt)
  end
end

local do_in_environment = function(chunk, env)
  arguments(
      "function", chunk,
      "table", env
    )

  setfenv(chunk, env)

  -- TODO: Add deadlock and memory protection
  -- TODO: Restore environment?

  return xpcall(chunk, debug.traceback)
end

-- TODO: Add option to forbid loading bytecode (on by default)
local dostring_in_environment = function(code, env, chunkname)
  arguments(
      "string", code,
      "table", env
    )

  local fn, err = loadstring(code, chunkname)
  if not fn then
    return nil, err
  end

  return do_in_environment(fn, env)
end

--------------------------------------------------------------------------------

return
{
  make_config_environment = make_config_environment;
  do_in_environment = do_in_environment;
  dostring_in_environment = dostring_in_environment;
}
