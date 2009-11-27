-- priority_queue.lua: queue of objects sorted by priority
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

local lower_bound
      = import 'lua-nucleo/algorithm.lua'
      {
        'lower_bound'
      }

--------------------------------------------------------------------------------

local table_insert, table_remove = table.insert, table.remove

--------------------------------------------------------------------------------

local make_priority_queue
do
  local PRIORITY_KEY = 1
  local VALUE_KEY = 2

  local insert = function(self, priority, value)
    method_arguments(
        self,
        "number", priority
      )
    -- value may be of any type, including nil

    local queue = self.queue_
    local k = lower_bound(queue, PRIORITY_KEY, priority)

    table_insert(queue, k, { [PRIORITY_KEY] = priority, [VALUE_KEY] = value })
  end

  local front = function(self)
    method_arguments(
        self
      )

    local queue = self.queue_
    local front_elem = queue[1]

    if front_elem == nil then
      return nil
    end

    return front_elem[PRIORITY_KEY], front_elem[VALUE_KEY]
  end

  local pop = function(self)
    method_arguments(
        self
      )

    local front_elem = table_remove(self.queue_, 1)
    if front_elem == nil then
      return nil
    end

    return front_elem[PRIORITY_KEY], front_elem[VALUE_KEY]
  end

  make_priority_queue = function()
    return
    {
      insert = insert;
      front = front;
      pop = pop;
      --
      queue_ = { };
    }
  end
end

return
{
  make_priority_queue = make_priority_queue;
}