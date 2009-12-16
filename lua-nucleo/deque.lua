-- deque.lua: double-ended queue wrapper
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local setmetatable = setmetatable
local table_remove, table_insert = table.remove, table.insert

-- Note: operations with back are significantly faster
--       than operations with front.
local make_deque
do
  local size = function(self)
    return #self
  end

  -- Not letting user to affect us with setting self[0] on construction
  local back = function(self)
    local size = #self
    if size > 0 then
      return self[size]
    end
    return nil
  end

  local front = function(self)
    return self[1]
  end

  local push_back = function(self, data)
    assert(data ~= nil, "deque: can't push nil") -- Avoiding making holes
    self[#self + 1] = data
  end

  local push_front = function(self, data)
    assert(data ~= nil, "deque: can't push nil") -- Avoiding making holes
    table_insert(self, 1, data)
  end

  local pop_front = function(self)
    return table_remove(self, 1)
  end

  local pop_back = function(self)
    return table_remove(self)
  end

  local mt =
  {
    size = size;
    back = back;
    front = front;
    push_back = push_back;
    push_front = push_front;
    pop_front = pop_front;
    pop_back = pop_back;
  }
  mt.__index = mt;
  mt.__metatable = true

  make_deque = function(data)
    if data then
      assert(
          getmetatable(data) == nil,
          "can't create deque on data with metatable"
        )
    end
    return setmetatable(data or { }, mt)
  end
end

return
{
  make_deque = make_deque;
}
