-- history.lua: Markov chain history
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Why Markov? Isn't this implementation generic enough?
-- TODO: Actually this is a ring buffer!

local assert, ipairs, unpack = assert, ipairs, unpack
local table_remove, table_insert, table_concat
    = table.remove, table.insert, table.concat

local is_table,
      is_number,
      is_string,
      is_self,
      is_nil
      = import 'lua-nucleo/type.lua'
      {
        'is_table',
        'is_number',
        'is_string',
        'is_self',
        'is_nil'
      }

local make_history
do
  -- TODO: Make configurable, so that table.concat(history:get())
  --       would work better for string history items.
  local DELIM = "\0"

  local h_push = function(self, item)
    assert(is_self(self))
    assert(item ~= nil)

    local data = self.data_

    table_remove(data, 1) -- Remove oldest item
    table_insert(data, item) -- Add newest item
  end

  local h_get = function(self)
    assert(is_self(self))
    return unpack(self.data_)
  end

  -- Warning: Do not call push() while iterating
  local h_ipairs = function(self)
    assert(is_self(self))
    return ipairs(self.data_)
  end

  make_history = function(seq_length)
    assert(is_number(seq_length), "bad sequence length")

    local data = { }
    for i = 1, seq_length do
      data[i] = DELIM
    end

    return
    {
      DELIM = DELIM;
      --
      push = h_push;
      get = h_get;
      ipairs = h_ipairs;
      --
      data_ = data;
    }
  end
end

return
{
  make_history = make_history;
}
