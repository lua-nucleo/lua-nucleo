--------------------------------------------------------------------------------
-- key_value_store_simple.lua: store for key-falue, fast to add and enumerate
-- Simple implementation
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local table_sort
      = import "lua-nucleo/quicksort.lua"
      {
        "quicksort"
      }

--------------------------------------------------------------------------------

local make_simple_key_value_store
do
  local empty = function(self)
    return self.num_values_ == 0
  end

  local can_add = function(self)
    return self.num_values_ < self.max_values_
  end

  local add = function(self, key, value)
    self.set_[#self.set_ + 1] =
    {
      key = key;
      value = value;
    }

    self.num_values_ = self.num_values_ + 1
  end

  local sort = function(self)
    table_sort(self.set_, self.key_sort_pred_)
  end

  local for_each_key = function(self, key_processor)
    for i = 1, #self.set_ do
      key_processor(self.set_[i].key)
    end
  end

  local for_each_value = function(self, value_processor)
    for i = 1, #self.set_ do
      value_processor(self.set_[i].value)
    end
  end

  local for_each_keyvalue = function(self, keyvalue_processor)
    for i = 1, #self.set_ do
      local entry = self.set_[i]
      keyvalue_processor(entry.key, entry.value)
    end
  end

  local create_sort_pred = function(key_comp)
    return function(lhs, rhs)
      return key_comp(lhs.key, rhs.key)
    end
  end

  local clear = function(self)
    self.set_ = { }
    self.num_values_ = 0
  end

  make_simple_key_value_store = function(max_values, key_comp)
    local set = { }

    return
    {
      empty = empty;
      clear = clear;
      can_add = can_add;
      add = add;
      sort = sort;
      for_each_key = for_each_key;
      for_each_value = for_each_value;
      for_each_keyvalue = for_each_keyvalue;
      --
      key_sort_pred_ = create_sort_pred(key_comp);
      max_values_ = max_values;
      set_ = set; -- just an array of <key,value> pairs
      num_values_ = 0; -- number of items, in current implementation == #set_
    }
  end

end

--------------------------------------------------------------------------------

return
{
  make_simple_key_value_store = make_simple_key_value_store;
}
