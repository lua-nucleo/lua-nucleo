--------------------------------------------------------------------------------
--- Queue of objects sorted by time
-- @module lua-nucleo.times_queue
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local math_huge = math.huge

--------------------------------------------------------------------------------

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

local make_priority_queue
      = import 'lua-nucleo/priority_queue.lua'
      {
        'make_priority_queue'
      }

--------------------------------------------------------------------------------

local make_timed_queue
do
  local insert = function(self, expiration_time, value)
    method_arguments(
        self,
        "number", expiration_time
      )
    assert(expiration_time >= 0, "negative time is not supported")
    assert(expiration_time ~= math_huge, "infinite time is not supported")
    assert(value ~= nil) -- TODO: Need *arguments metatype for that

    self.priority_queue_:insert(expiration_time, value)
  end

  -- TODO: Batch element removal?
  local pop_next_expired = function(self, time_current)
    method_arguments(
        self,
        "number", time_current
      )

    local time_of_first_elem = (self.priority_queue_:front())
    if time_of_first_elem and time_of_first_elem <= time_current then
      return self.priority_queue_:pop()
    end

    return nil
  end

  local get_next_expiration_time = function(self)
    method_arguments(
        self
      )

    return (self.priority_queue_:front()) or math_huge
  end

  make_timed_queue = function()

    return
    {
      insert = insert;
      pop_next_expired = pop_next_expired;
      get_next_expiration_time = get_next_expiration_time;
      --
      priority_queue_ = make_priority_queue();
    }
  end
end

return
{
  make_timed_queue = make_timed_queue;
}
