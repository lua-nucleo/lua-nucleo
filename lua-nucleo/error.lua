--------------------------------------------------------------------------------
-- error.lua: error handling convenience wrapper
-- This file is a part of Lua-Nucleo library
-- Copyright (c) Lua-Aplicado authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local debug_traceback = debug.traceback

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

local make_loggers
      = import 'lua-nucleo/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("lua-nucleo/error", "ERR")

--------------------------------------------------------------------------------

local error_tag = unique_object()

local is_error_object = function(err)
  return not not (is_table(err) and err[1] == error_tag)
end

local error_handler_for_call = function(msg)
  if not is_error_object(msg) then
    msg = debug_traceback(msg)
    log_error(msg)
  else
    spam("caught: ", debug_traceback(msg[2])) -- Required for debugging
  end
  return msg
end

local create_error_object = function(error_id)
  return { error_tag, error_id }
end

local get_error_id = function(err)
  if is_error_object(err) then
    return err[2]
  end
  return nil
end

local throw = function(error_id)
  return error(create_error_object(error_id))
end

local pcall_adaptor_for_call = function(status, ...)
  if not status then
    local err = (...)

    local error_id = get_error_id(err)
    if error_id ~= nil then
      return nil, error_id
    end

    return error(err) -- Not our error, rethrow
  end
  return ... -- NOTE: Shouldn't we return true here?
end

--------------------------------------------------------------------------------

local call = function(fn, ...)
  local nargs, args = select("#", ...), { ... }
  return pcall_adaptor_for_call(
      xpcall(
          function()
            return fn(unpack(args, 1, nargs))
          end,
          error_handler_for_call
        )
    )
end

local fail = function(error_id, msg)
  arguments(
      "string", error_id,
      "string", msg
    )

  log_error(msg)
  throw(error_id)
end

local try = function(error_id, result, err, ...)
  arguments(
      "string", error_id
    )

  if result == nil then
    fail(error_id, err or "no error message")
  end

  return result, err, ...
end

local rethrow = function(error_id, err)
  if not is_error_object(err) then
    return fail(error_id, err)
  end
  error(err) -- Rethrowing our error, ignoring error_id
end

--------------------------------------------------------------------------------

--- Simple finalizer
local xfinally, xcall
do
  local pack_pcall_results = function(ok, ...)
    return ok, { ... }
  end

  xfinally = function(fn, cleanup_fn)
    local ok, ret = pack_pcall_results(xpcall(fn, error_handler_for_call))
    local cleaned, err = xpcall(cleanup_fn, error_handler_for_call)
    if cleaned then
      if ok then
        return unpack(ret)
      else
        error(ret[1])
      end
    else
      if not ok then
        error(ret[1])
      else
        error(err)
      end
    end
  end

  xcall = function(fn, cleanup_fn)
    local ok, ret = pack_pcall_results(xpcall(fn, error_handler_for_call))
    local cleaned, cleanup_error = xpcall(cleanup_fn, error_handler_for_call)
    if cleaned then
      if ok then
        -- all ok: both fn() and cleanup_fn()
        return true, unpack(ret)
      else
        return nil, ret[1], true
      end
    else
      if not ok then
        return nil, ret[1], nil, cleanup_error
      else
        -- fn() ok, but finalizer is not
        return nil, nil, nil, cleanup_error
      end
    end
  end
end

--------------------------------------------------------------------------------

return
{
  call = call;
  try = try;
  fail = fail;
  rethrow = rethrow;
  xfinally = xfinally;
  xcall = xcall;
  -- semi-public, for unit tests
  create_error_object = create_error_object;
  is_error_object = is_error_object;
  error_handler_for_call = error_handler_for_call;
  get_error_id = get_error_id;
}
