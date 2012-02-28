--------------------------------------------------------------------------------
-- pcall.lua: part of coro.lua -- coroutine module extensions
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local setmetatable = setmetatable

local coroutine = coroutine
local coroutine_create, coroutine_resume, coroutine_yield =
      coroutine.create, coroutine.resume, coroutine.yield

local resume_inner
      = import 'lua-nucleo/coro.lua'
      {
        'resume_inner'
      }

local pcall
do
  local coroutine_cache = setmetatable(
      {},
      {
        __mode = "k";
        __index = function(t, k)
          local v = coroutine.create(k)
          t[k] = v
          return v
        end;
      }
    )

  pcall = function(f, ...)
    -- TODO: What if f() contains native coroutine.yield() call?!
    return resume_inner(coroutine_cache[f], ...)
  end
end

return
{
  pcall = pcall;
}
