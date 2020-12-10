--------------------------------------------------------------------------------
--- Sandbox-related stuff
-- @module lua-nucleo.sandbox
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Move more code here

--------------------------------------------------------------------------------

local setmetatable, setfenv, xpcall, loadstring, load, debug
    = setmetatable, setfenv, xpcall, loadstring, load, debug

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

local do_in_environment = function(chunk, env, chunkname)
  arguments(
      "function", chunk,
      "table", env
    )
  optional_arguments(
      "string", chunkname
    )

  if setfenv then
    setfenv(chunk, env)
  else
    chunk = load(chunk, chunkname or '[sandbox]', nil, env)
  end

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

  local fn, err
  if loadstring then
    fn, err = loadstring(code, chunkname)
  else
    fn, err = load(code, chunkname, 't', env)
  end

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
