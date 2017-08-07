--------------------------------------------------------------------------------
--- Schema-agnostic DSL data loader
-- @module lua-nucleo.dsl.dsl_loader
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments,
      eat_true
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments',
        'eat_true'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local tappend_many
      = import 'lua-nucleo/table-utils.lua'
      {
        'tappend_many'
      }

local assert_is_table,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_function'
      }

--------------------------------------------------------------------------------

local create_common_fields_by_tag
do
  create_common_fields_by_tag = function(fields)
    assert(fields ~= nil)

    if not is_table(fields) then
      fields = { fields }
    end

    return setmetatable(
        { },
        {
          __index = function(t, tag)
            local v = fields
            t[tag] = v
            return v
          end
        }
      )
  end
end

-- NOTE: This filter does not support data-only calls.
--       See tests for example of filter that does.
local create_common_name_filter = function(tag_field, fields_by_tag)
  -- tag_field may be nil
  assert_is_table(fields_by_tag)

  return function(tag_value, ...)
    assert(tag_value ~= nil, "missing tag value")

    local fields = assert_is_table(fields_by_tag[tag_value], "unknown tag")
    assert(select("#", ...) == #fields, "bad number of arguments")

    local result = { }

    if tag_field ~= nil then
      result[tag_field] = tag_value
    end

    for i = 1, #fields do
      result[fields[i]] = select(i, ...)
    end

    return result
  end
end

--------------------------------------------------------------------------------

local make_dsl_loader
do
  local mt_tag = unique_object()

  -- Can't use nil due to heavy __index usage.
  local not_set_marker = unique_object()

  local data_filter_key = unique_object()
  local name_filter_key = unique_object()
  local tag_value_key = unique_object()
  local data_key = unique_object()
  local expected_self_key = unique_object()

  local make_storage = function(
      data_filter,
      name_filter,
      tag_value,
      data,
      expected_self
    )
    assert_is_function(data_filter, "bad data filter")
    assert_is_function(name_filter, "bad name filter")
    assert(tag_value ~= nil, "missing tag value")
    assert(data ~= nil, "missing data")
    assert(expected_self ~= nil, "missing expected self")

    return
    {
      [data_filter_key] = data_filter;
      [name_filter_key] = name_filter;
      [tag_value_key] = tag_value;
      [data_key] = data;
      [expected_self_key] = expected_self;
    }
  end

  local finalize_storage = function(storage, data)
    return storage[data_filter_key](storage[data_key], data)
  end

  local finalize_data_impl
  do
    local function impl(data, visited)
      assert(visited[data] == nil, "recursion detected")
      visited[data] = true

      if getmetatable(data) == mt_tag then
        data = finalize_storage(data, { })
      end

      for k, v in pairs(data) do
        if is_table(k) and getmetatable(k) == mt_tag then
          -- Limitation to simplify implementation.
          -- Don't want to deal with changing keys.
          error("DSL data in keys is not supported")
        end

        if is_table(v) then
          data[k] = impl(v, visited)
        end
      end

      visited[data] = nil

      return data
    end

    finalize_data_impl = function(data)
      if not is_table(data) then
        return data
      end

      return impl(data, { })
    end
  end

  local finalize_many
  do
    local function impl(n, data, ...)
      if n > 1 then
        return finalize_data_impl(data), impl(n - 1, ...)
      end

      return finalize_data_impl(data)
    end

    finalize_many = function(...)
      return impl(select("#", ...), ...)
    end
  end

  local tertiary_mt =
  {
    __metatable = mt_tag;

    __index = function(t, v)
      error("you should call this object, not index it", 2)
    end;

    __newindex = function(t, k, v)
      error("this is a constant object", 2)
    end;

    __call = function(t, data, ...)
      assert(select("#", ...) == 0, "extra arguments are not supported")
      assert(data ~= nil, "missing call arguments")

      return finalize_storage(
          t,
          finalize_data_impl(data)
        )
    end;
  }

  local secondary_mt =
  {
    __metatable = mt_tag;

    __index = function(t, v)
      error("you should call this object, not index it", 2)
    end;

    __newindex = function(t, k, v)
      error("this is a constant object", 2)
    end;

    __call = function(t, self, ...)
      if self ~= t[expected_self_key] then
        error("dot call is not supported", 2)
      end

      -- We need a separate early filter to guarantee
      -- that filter call order matches dsl call order.
      local data = t[name_filter_key](t[tag_value_key], finalize_many(...))

      assert(data ~= nil, "broken name filter")

      return setmetatable(
          make_storage(
              t[data_filter_key],
              t[name_filter_key],
              t[tag_value_key],
              data,
              t[expected_self_key]
            ),
          tertiary_mt
        )
    end;
  }

  local primary_mt =
  {
    __metatable = mt_tag;

    __index = function(t, tag)
      return setmetatable(
          make_storage(
              t[data_filter_key],
              t[name_filter_key],
              tag,
              not_set_marker,
              t
            ),
          secondary_mt
        )
    end;

    __newindex = function(t, k, v)
      error("this is a constant object", 2)
    end;
  }

  local get_interface = function(self)
    method_arguments(self)

    return self.interface_
  end

  local finalize_data = function(self, data)
    method_arguments(
        self,
        "table", data
      )
    assert(data ~= self) -- May lead to nasty problems

    return finalize_data_impl(data)
  end

  local default_data_filter = function(t, data)
    assert_is_table(data, "data should be a table")
    return tappend_many(t, data)
  end

  make_dsl_loader = function(name_filter, data_filter)
    data_filter = data_filter or default_data_filter

    arguments(
        "function", name_filter,
        "function", data_filter
      )

    return
    {
      get_interface = get_interface;
      finalize_data = finalize_data;
      --
      interface_ = setmetatable(
          make_storage(
              data_filter,
              name_filter,
              not_set_marker, -- no tag yet
              not_set_marker, -- no data yet
              not_set_marker  -- no self expected yet
            ),
          primary_mt
        );
    }
  end
end

--------------------------------------------------------------------------------

return
{
  create_common_fields_by_tag = create_common_fields_by_tag;
  create_common_name_filter = create_common_name_filter;
  --
  make_dsl_loader = make_dsl_loader;
}
