--------------------------------------------------------------------------------
--- Various useful stuff
-- @module lua-nucleo.misc
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: There should be no misc.lua! Split this file to specialized files!

local collectgarbage = collectgarbage

local unique_object = function()
  -- newproxy() would be faster, but it is undocumented.
  -- Note that table is not acceptable, since its contents are not constant.
  return function() end
end

-- TODO: Test this!
local collect_all_garbage = function()
  local now = collectgarbage("count")
  local prev = 0
  local count = 0
  -- Need count > 2 to ensure two-pass userdata collection is completed.
  -- On the first pass __gc is called and userdata is not collected
  -- (thus memory count is not changed).
  while prev ~= now or count < 2 do
    collectgarbage("collect")
    prev, now = now, collectgarbage("count")
    count = count + 1
    assert(count < 1e3, "infinite loop detected")
  end
end

return
{
  unique_object = unique_object;
  collect_all_garbage = collect_all_garbage;
}
