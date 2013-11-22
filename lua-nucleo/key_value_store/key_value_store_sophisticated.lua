--------------------------------------------------------------------------------
-- key_value_store_sophisticated.lua: store for key-falue
-- Implementation using order preserving hash and trying to sort during addition
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local socket = require "socket"

-- Necessary for debug info output
--local ffi = require "ffi"

--------------------------------------------------------------------------------

local upper_bound_pred
      = import 'lua-nucleo/algorithm.lua'
      {
        'upper_bound_pred'
      }

local table_sort, table_insert = table.sort, table.insert

--------------------------------------------------------------------------------

local MAX_BUCKET_SIZE = 1024 * 1024 * 1024

--------------------------------------------------------------------------------

local make_key_value_store_sophisticated
do
  local dummy_ophash_comp = function(key1, key2)
    error("Dummy hash comp was called")
  end

  local create_bucket = function()
    return
    {
      sorted = true,
      key_hits = 0
    }
  end

  local sort_buckets = function(buckets, pred)
    local sorted_buckets = { }
    for k,v in pairs(buckets) do
      sorted_buckets[#sorted_buckets + 1] = { bkey = k, items = v }
    end
    table_sort(sorted_buckets, pred)
    return sorted_buckets
  end


  local empty = function(self)
    return self.num_values_ == 0
  end

  local can_add = function(self)
    return self.num_values_ < self.max_values_
  end

  local add = function(self, key, value, hash)
    -- debug info calculation
    --local beg_time = socket.gettime()

    local bucket = self.buckets_[hash]

    local added = false

    if not bucket then
      bucket = create_bucket()
      self.buckets_[hash] = bucket

      -- debug info output
      --dbg("new bucket", ffi.string(key.data, key.size))

    elseif bucket.sorted then
      -- Try to insert to existing bucket item
      if #bucket < self.max_bucket_size_for_inplace_sort_ then
        local pos = upper_bound_pred(bucket, "key", key, self.key_sort_pred_)

        -- debug info output
        --dbg("upper_bound_pred", ffi.string(key.data, key.size), pos)

        if pos > 1 then
          local bucket_item = bucket[pos-1]
          if
            not self.key_sort_pred_(bucket_item.key, key) and
            not self.key_sort_pred_(key, bucket_item.key)
          then
            -- Key exists
            local values = bucket_item.values
            if not values then
              values = { bucket_item.value }
              bucket_item.values = values
              bucket_item.value = false
            end
            values[#values + 1] = value
            bucket.key_hits = bucket.key_hits + 1
          else
            -- New key
            table_insert(bucket, pos, { key = key, value = value })
          end
        else
          -- New key and it is the least one
          table_insert(bucket, 1, { key = key, value = value })
        end
        added = true
      else
        -- Too much elements in the bucket - stop inplace sorting
        bucket.sorted = false
        self.bucket_data_sorted_ = false
      end
    end

    -- Create new bucket item if failed to add

    if not added then
      bucket[#bucket + 1] = { key = key, value = value }
    end

    self.num_values_ = self.num_values_ + 1

    -- debug info calculation
    --self.time_add_ = self.time_add_ + socket.gettime() - beg_time
  end

  local sort = function(self)
    if self.bucket_data_sorted_ then
      return false
    end

    -- debug info calculation
    local beg_time = socket.gettime()
    local num_buckets, num_sorted_buckets = 0, 0

    for k,v in pairs(self.buckets_) do
      -- debug info calculation
      num_buckets = num_buckets + 1

      if not v.sorted then
        table_sort(v, self.wrapped_key_sort_pred_)
        v.sorted = true

        -- debug info calculation
        num_sorted_buckets = num_sorted_buckets + 1
      end
    end

    -- debug info calculation
    self.time_sort_ = self.time_sort_ + socket.gettime() - beg_time

    -- debug info output
    --dbg("num newly sorted buckets: ", num_sorted_buckets, "/", num_buckets)

    self.bucket_data_sorted_ = true
    return true
  end

  local for_each_key = function(self, key_processor)

    self:sort()

    -- debug info calculation
    --local beg_time = socket.gettime()

    local sorted_buckets = sort_buckets(self.buckets_, self.bucket_sort_pred_)
    for i = 1, #sorted_buckets do
      local bucket = (sorted_buckets[i].items)
      for j = 1, #bucket do
        key_processor(bucket[j].key)
      end
    end

    -- debug info calculation
    --self.time_for_each_key_ =
    --  self.time_for_each_key_ + socket.gettime() - beg_time

    -- debug info output
    --[[
    dbg(
        "for_each_key time:", self.time_for_each_key_,
        "bucket data sort time:", self.time_sort_
      )
    ]]
  end

  local for_each_value = function(self, value_processor)

    self:sort()

    -- debug info calculation
    --local beg_time = socket.gettime()

    local sorted_buckets = sort_buckets(self.buckets_, self.bucket_sort_pred_)
    for i = 1, #sorted_buckets do
      local bucket = assert(sorted_buckets[i].items)
      for j = 1, #bucket do
        if bucket[j].value then
          value_processor(bucket[j].value)
        else
          local values = bucket[j].values
          for k = 1, #values do
            value_processor(values[k])
          end
        end
      end
    end

    -- debug info calculation
    --self.time_for_each_value_ =
    --  self.time_for_each_value_ + socket.gettime() - beg_time

    -- debug info output
    --[[
    dbg(
        "for_each_value time:", self.time_for_each_value_,
        "bucket data sort time:", self.time_sort_
      )
    ]]
  end

  local for_each_keyvalue = function(self, keyvalue_processor)

    self:sort()

    -- debug info calculation
    local beg_time = socket.gettime()

    -- debug info calculation
    local overall_keys, overall_items, overall_hits = 0, 0, 0

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

      -- debug info calculation
      local num_items = 0

      for j = 1, #bucket do
        if bucket[j].value then
          keyvalue_processor(bucket[j].key, bucket[j].value)
          -- debug info calculation
          num_items = num_items + 1
        else
          local key, values = bucket[j].key, bucket[j].values
          local q = #values
          for k = 1, q do
            keyvalue_processor(key, values[k])
          end
          -- debug info calculation
          num_items = num_items + q
        end
      end

      -- debug info output
      --[[
      dbg(
          "bucket", i, "keys =", #bucket,
          "q =" , num_items, "key hits =", bucket.key_hits,
          "(",  tostring(bucket.key_hits / num_items * 100) .. "%", ")"
        )
      ]]

      -- debug info calculation
      overall_keys = overall_keys + #bucket
      overall_items = overall_items + num_items
      overall_hits = overall_hits + bucket.key_hits
    end

    -- debug info output
    log(
      "overall keys =", overall_keys,
      "q =" , overall_items, "key hits =", overall_hits,
      "(",  tostring(overall_hits / overall_items * 100) .. "%", ")"
    )

    -- debug info output
    log("min bucket size:", min_bucket_size, "max bucket size:", max_bucket_size)

    -- debug info calculation
    self.time_for_each_keyvalue_ =
      self.time_for_each_keyvalue_ + socket.gettime() - beg_time

    -- debug info output
    log(
        "for_each_keyvalue time:", self.time_for_each_keyvalue_,
        "bucket data sort time:", self.time_sort_
      )
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
    self.bucket_data_sorted_ = true
  end

  make_key_value_store_sophisticated = function(
      max_values,
      key_comp,
      order_preserving_hash_comp,
      max_bucket_size_for_inplace_sort
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
      key_sort_pred_ = key_comp;
      wrapped_key_sort_pred_ = create_key_sort_pred(key_comp);
      bucket_sort_pred_ = create_bucket_sort_pred(order_preserving_hash_comp or dummy_ophash_comp);
      max_values_ = max_values;
      max_bucket_size_for_inplace_sort_ = max_bucket_size_for_inplace_sort;

      buckets_ = { };
      num_values_ = 0;
      bucket_data_sorted_ = true;

      time_add_               = 0;
      time_sort_              = 0;
      time_for_each_key_      = 0;
      time_for_each_value_    = 0;
      time_for_each_keyvalue_ = 0;
    }
  end

end

return
{
  make_key_value_store_sophisticated = make_key_value_store_sophisticated
}
