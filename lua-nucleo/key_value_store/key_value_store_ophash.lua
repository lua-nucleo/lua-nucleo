--------------------------------------------------------------------------------
-- key_value_store_ophash.lua: store for key-falue, fast to add and enumerate
-- Implemenation using order preserving hash
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- debug info calculation
--local socket = require "socket"

--------------------------------------------------------------------------------

local table_sort = table.sort

--------------------------------------------------------------------------------

local MAX_BUCKET_SIZE = 1024 * 1024 * 1024

--------------------------------------------------------------------------------

local make_ophash_key_value_store
do
  local dummy_ophash_comp = function(key1, key2)
    error("Dummy hash comp was called")
  end

  local sort_buckets = function(buckets, pred)
    local sorted_buckets = { }
    for k,v in pairs(buckets) do
      sorted_buckets[#sorted_buckets + 1] = { bkey = k, items = v }
    end
    table_sort(sorted_buckets, pred)
    -- debug info output
    --dbg("num buckets:", #sorted_buckets)
    return sorted_buckets
  end

  local empty = function(self)
    return self.num_values_ == 0
  end

  local can_add = function(self)
    return self.num_values_ < self.max_values_
  end

  local add = function(self, key, value, hash)

    local bucket = self.buckets_[hash]
    if not bucket then
      bucket = { }
      self.buckets_[hash] = bucket
    end

    bucket[#bucket + 1] = { key = key, value = value }

    self.num_values_ = self.num_values_ + 1
    self.sorted_ = false
  end

  local sort = function(self)
    if self.sorted_ then
      return false
    end

    -- debug info calculation
    --local beg_time = socket.gettime()

    for k,v in pairs(self.buckets_) do
      table_sort(v, self.key_sort_pred_)
    end

    -- debug info calculation
    --self.time_sort_ = self.time_sort_ + socket.gettime() - beg_time
    -- debug info output
    --dbg("bucket data sort time:", self.time_sort_)

    self.sorted_ = true
    return true
  end

  local for_each_key = function(self, key_processor)
    self:sort()
    local sorted_buckets = sort_buckets(self.buckets_, self.bucket_sort_pred_)
    for i = 1, #sorted_buckets do
      local bucket = assert(sorted_buckets[i].items)
      for i = 1, #bucket do
        key_processor(bucket[i].key)
      end
    end
  end

  local for_each_value = function(self, value_processor)
    self:sort()
    local sorted_buckets = sort_buckets(self.buckets_, self.bucket_sort_pred_)
    for i = 1, #sorted_buckets do
      local bucket = assert(sorted_buckets[i].items)
      for i = 1, #bucket do
        value_processor(bucket[i].value)
      end
    end
  end

  local for_each_keyvalue = function(self, keyvalue_processor)
    self:sort()
    local sorted_buckets = sort_buckets(self.buckets_, self.bucket_sort_pred_)
    local min_bucket_size, max_bucket_size = MAX_BUCKET_SIZE, 0
    for i = 1, #sorted_buckets do
      local bucket = assert(sorted_buckets[i].items)

      local bucket_size = #bucket
      if min_bucket_size > bucket_size  then
        min_bucket_size = bucket_size
      end
      if max_bucket_size < bucket_size  then
        max_bucket_size = bucket_size
      end

      for i = 1, #bucket do
        local entry = bucket[i]
        keyvalue_processor(entry.key, entry.value)
      end
    end

    -- debug info output
    --dbg("min bucket size:", min_bucket_size, "max bucket size:", max_bucket_size)
  end

  local create_key_sort_pred = function(key_comp)
    return function(lhs, rhs)
      return key_comp(lhs.key, rhs.key)
    end
  end

  local create_bucket_sort_pred = function(bucket_comp)
    return function(lhs, rhs)
      return bucket_comp(lhs.bkey, rhs.bkey)
    end
  end

  local clear = function(self)
    self.buckets_ = { }
    self.num_values_ = 0
    self.sorted_ = true
  end

  make_ophash_key_value_store = function(
      max_values,
      key_comp,
      order_preserving_hash_comp
    )
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
      key_sort_pred_ = create_key_sort_pred(key_comp);
      bucket_sort_pred_ = create_bucket_sort_pred(order_preserving_hash_comp or dummy_ophash_comp);
      max_values_ = max_values;
      buckets_ = { };
      num_values_ = 0;
      sorted_ = true;
      time_sort_ = 0;
    }
  end

end

--------------------------------------------------------------------------------

return
{
  make_ophash_key_value_store = make_ophash_key_value_store;
}
