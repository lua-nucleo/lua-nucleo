--------------------------------------------------------------------------------
-- 0470-dsl-dsl_loader.lua: Tests for schema-agnostic DSL data loader
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- WARNING! Many of these tests fail at unpredictable times on Lua 5.3 and
-- always fail on Lua 5.2
-- See https://github.com/lua-nucleo/lua-nucleo/issues/56

local is_lua52_or_lua53 = _VERSION == 'Lua 5.2' or _VERSION == 'Lua 5.3'

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local assert_is_table,
      assert_is_nil
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_nil'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_tdeepequals,
      ensure_error,
      ensure_returns,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals',
        'ensure_tdeepequals',
        'ensure_error',
        'ensure_returns',
        'ensure_fails_with_substring'
      }

local tclone,
      tset,
      tappend_many,
      twithdefaults
      = import 'lua-nucleo/table.lua'
      {
        'tclone',
        'tset',
        'tappend_many',
        'twithdefaults'
      }

--------------------------------------------------------------------------------

local create_common_fields_by_tag,
      create_common_name_filter,
      make_dsl_loader,
      dsl_loader_exports
      = import 'lua-nucleo/dsl/dsl_loader.lua'
      {
        'create_common_fields_by_tag',
        'create_common_name_filter',
        'make_dsl_loader'
      }

--------------------------------------------------------------------------------

local TAG = "xTAGx"
local NAME = "xNAMEx"

local simple_name_filter = function(tag_value, name_value, ...)
  ensure_equals("no extra arguments", select("#", ...), 0)
  
  if is_table(name_value) then -- data-only-call
    assert_is_nil(name_value[TAG], "simple_name_filter: tag field is reserved")
    
    name_value[TAG] = tag_value
    
    return name_value
  end

  return
  {
    [TAG] = tag_value;
    [NAME] = name_value;
  }
end

--------------------------------------------------------------------------------

local test = (...)("dsl_loader", dsl_loader_exports)

--------------------------------------------------------------------------------

test:tests_for "create_common_fields_by_tag"

--------------------------------------------------------------------------------

test "create_common_fields_by_tag-string" (function()
  local field = "alpha"

  local fields_by_tag = create_common_fields_by_tag(field)

  ensure_tdeepequals(
      "check fields_by_tag",
      fields_by_tag["foo"],
      { field }
    )
end)

test "create_common_fields_by_tag-table" (function()
  local fields = { "alpha", "beta" }

  local fields_by_tag = create_common_fields_by_tag(fields)

  ensure_tdeepequals(
      "check fields_by_tag",
      fields_by_tag["bar"],
      fields
    )
end)

--------------------------------------------------------------------------------

test:tests_for "create_common_name_filter"

--------------------------------------------------------------------------------

test "create_common_name_filter-simple" (function()
  local fields_by_tag =
  {
    alpha = { "one", "two" };
    beta = { "three" };
    gamma = { };
  }

  local filter = create_common_name_filter("tag", fields_by_tag)

  ensure_tdeepequals(
      "alpha",
      filter("alpha", 1, 2),
      {
        tag = "alpha";
        one = 1;
        two = 2;
      }
    )

  ensure_tdeepequals(
      "beta",
      filter("beta", 3),
      {
        tag = "beta";
        three = 3;
      }
    )

  ensure_tdeepequals(
      "gamma",
      filter("gamma"),
      {
        tag = "gamma";
      }
    )
end)

test "create_common_name_filter-no-tag" (function()
  local fields_by_tag =
  {
    alpha = { "one", "two" };
    beta = { "three" };
    gamma = { };
  }

  local filter = create_common_name_filter(nil, fields_by_tag)

  ensure_tdeepequals(
      "alpha",
      filter("alpha", 1, 2),
      {
        one = 1;
        two = 2;
      }
    )

  ensure_tdeepequals(
      "beta",
      filter("beta", 3),
      {
        three = 3;
      }
    )

  ensure_tdeepequals(
      "gamma",
      filter("gamma"),
      {
      }
    )
end)

test "create_common_name_filter-unknown-tag" (function()
  local fields_by_tag =
  {
    alpha = { "one" };
  }

  local filter = create_common_name_filter("tag", fields_by_tag)

  ensure_fails_with_substring(
      "unknown tag",
      function()
        filter("my_unknown_tag", 1)
      end,
      "unknown tag"
    )
end)

test "create_common_name_filter-bad-number-of-arguments" (function()
  local fields_by_tag =
  {
    alpha = { "one" };
    beta = { };
  }

  local filter = create_common_name_filter("tag", fields_by_tag)

  ensure_fails_with_substring(
      "alpha: none",
      function()
        filter("alpha")
      end,
      "bad number of arguments"
    )

  ensure_fails_with_substring(
      "alpha: too many",
      function()
        filter("alpha", 1, 2)
      end,
      "bad number of arguments"
    )

  ensure_fails_with_substring(
      "beta: too many",
      function()
        filter("beta", 1)
      end,
      "bad number of arguments"
    )
end)

--------------------------------------------------------------------------------

test:factory "make_dsl_loader" (
    function() return make_dsl_loader(simple_name_filter) end
  )

--------------------------------------------------------------------------------

test:methods "get_interface"

--------------------------------------------------------------------------------

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-full-call" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "check returned data",
      dsl_loader:finalize_data(api:call "name" { value = 1 }),
      {
        [TAG] = "call";
        [NAME] = "name";
        value = 1;
      }
    )
end)

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-name-only-call" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "check returned data",
      dsl_loader:finalize_data(api:call "name"),
      {
        [TAG] = "call";
        [NAME] = "name";
      }
    )
end)

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-data-only-call" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "check returned data",
          dsl_loader:finalize_data(api:call { value = 1 }),
          {
            [TAG] = "call";
            value = 1;
          }
        )
    end
  )

--------------------------------------------------------------------------------
-- Implementation-specific tests
--------------------------------------------------------------------------------

-- NOTE: These are arbitrary tests. Change them if implementation changes.
-- NOTE: Some tests are not that arbitrary.

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-data-only-call-explicit-name" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "check returned data",
          dsl_loader:finalize_data(api:call { value = 1, [NAME] = "name" }),
          {
            [TAG] = "call";
            [NAME] = "name";
            value = 1;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-name-reserved-in-default-data-filter" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "name field is reserved",
          function()
            api:call "name" { value = 1, [NAME] = "myname" }
          end,
          "attempted to override table key `" .. NAME .. "'"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-tag-reserved-in-default-data-filter" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "tag field is reserved",
          function()
            api:call "name" { value = 1, [TAG] = "tag" }
          end,
          "attempted to override table key `" .. TAG .. "'"
        )
    end
  )

test "get_interface-primary-constant-object" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_fails_with_substring(
      "this is a constant object",
      function()
        api.foo = 42
      end,
      "this is a constant object"
    )
end)

test "get_interface-secondary-constant-object" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_fails_with_substring(
      "this is a constant object",
      function()
        api.foo.bar = 42
      end,
      "this is a constant object"
    )
end)

test "get_interface-secondary-index-fails" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_fails_with_substring(
      "this object is not indexable",
      function()
        local a = api.foo.bar
      end,
      "you should call this object, not index it"
    )
end)

test "get_interface-name-only-dot-call-fails" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_fails_with_substring(
      "dot call is not supported",
      function()
        local a = api.foo "name"
      end,
      "dot call is not supported"
    )
end)

test "get_interface-data-only-dot-call-fails" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_fails_with_substring(
      "dot call is not supported",
      function()
        local a = api.foo { value = 42 }
      end,
      "dot call is not supported"
    )
end)

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-tertiary-name-call-constant-object" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "this is a constant object",
          function()
            (api:foo "bar").baz = 42
          end,
          "this is a constant object"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-tertiary-name-call-index-fails" (function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "this object is not indexable",
          function()
            local a = (api:foo "bar").baz
          end,
          "you should call this object, not index it"
        )
      end
    )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-multiple-name-arguments-accepted" (
    function()
      local name_filter = function(tag_value, name_value, param_1, ...)
        ensure_equals("tag", tag_value, "foo")
        ensure_equals("name", name_value, "name")
        ensure_equals("param_1", param_1, 42)
        ensure_equals("no extra arguments", select("#", ...), 0)

        return
        {
          [TAG] = tag_value;
          [NAME] = name_value;
          param_1 = 42;
          extra = true;
        }
      end

      local dsl_loader = make_dsl_loader(name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "multiple name arguments passed through name filter",
          dsl_loader:finalize_data(api:foo ("name", 42) { value = 1 }),
          {
            [TAG] = "foo";
            [NAME] = "name";
            param_1 = 42;
            extra = true;
            value = 1;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-name-only-call-multiple-name-arguments-accepted" (
    function()
      local name_filter = function(tag_value, name_value, param_1, ...)
        ensure_equals("tag", tag_value, "foo")
        ensure_equals("name", name_value, "name")
        ensure_equals("param_1", param_1, 42)
        ensure_equals("no extra arguments", select("#", ...), 0)

        return
        {
          [TAG] = tag_value;
          [NAME] = name_value;
          param_1 = 42;
          extra = true;
        }
      end

      local dsl_loader = make_dsl_loader(name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "multiple name arguments passed through name filter",
          dsl_loader:finalize_data(api:foo ("name", 42)),
          {
            [TAG] = "foo";
            [NAME] = "name";
            param_1 = 42;
            extra = true;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-multiple-data-arguments-fails" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "multiple data arguments not supported",
          function()
            api:foo "bar" ({ value = 42 }, 42)
          end,
          "extra arguments are not supported"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-nil-name-passed-to-name-filter" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "nil name passed to name filter",
          dsl_loader:finalize_data(api:foo () { value = 42 }),
          {
            [TAG] = "foo";
            [NAME] = nil;
            value = 42;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-name-only-call-nil-name-passed-to-name-filter" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "nil name passed to name filter",
          dsl_loader:finalize_data(api:foo ()),
          {
            [TAG] = "foo";
            [NAME] = nil;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-string-data-fails-with-default_data_filter" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "should be a single table parameter with default data_filter",
          function()
            api:foo "name" ("value")
          end,
          "data should be a table"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-full-call-many-params-fails" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "should be a single parameter (was many)",
          function()
            api:foo "name" ("value1", "value2")
          end,
          "extra arguments are not supported"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-full-call-missing-data-fails" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "should be a single parameter (was nil)",
          function()
            api:foo "name" ()
          end,
          "missing call arguments"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53) "get_interface-full-call-non-string-name" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "returned value check",
          dsl_loader:finalize_data(api:call (42) { value = 1 }),
          {
            [TAG] = "call";
            [NAME] = 42;
            value = 1;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-name-only-call-non-string-name" (function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_tdeepequals(
          "returned value check",
          dsl_loader:finalize_data(api:call (42)),
          {
            [TAG] = "call";
            [NAME] = 42;
          }
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53)
  "get_interface-full-call-table-name-passed-to-name-filter" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "table name passed to name filter",
      dsl_loader:finalize_data(api:foo { param_1 = 1 } { value = 42 }),
      {
        [TAG] = "foo";
        param_1 = 1;
        value = 42;
      }
    )
end)

--------------------------------------------------------------------------------

test:methods "finalize_data"

--------------------------------------------------------------------------------

-- Note that finalize_data is partially tested by get_interface tests above

test "finalize_data-empty" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  local original_data = { }
  local resulting_data = dsl_loader:finalize_data(original_data)

  ensure_tdeepequals("data not changed", resulting_data, original_data)
end)

test:BROKEN_IF(is_lua52_or_lua53) "finalize_data-list-of-values" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "returned value check",
      dsl_loader:finalize_data(
          {
            api:alpha "one" { value = 1 };
            two = api:beta "two";
            { api:gamma "three" };
            four = { value = api:delta "four" };
          }
        ),
      {
        { [TAG] = "alpha", [NAME] = "one", value = 1 };

        two = { [TAG] = "beta", [NAME] = "two" };

        {
          { [TAG] = "gamma", [NAME] = "three" };
        };

        four =
        {
          value = { [TAG] = "delta", [NAME] = "four" };
        };
      }
    )
end)

test:BROKEN_IF(is_lua52_or_lua53) "finalize_data-dsl-in-keys-not-supported" (
    function()
      local dsl_loader = make_dsl_loader(simple_name_filter)
      local api = dsl_loader:get_interface()

      ensure_fails_with_substring(
          "DSL data in keys is not supported",
          function()
            dsl_loader:finalize_data({ [api:foo "alpha"] = true })
          end,
          "DSL data in keys is not supported"
        )
    end
  )

test:BROKEN_IF(is_lua52_or_lua53) "finalize_data-recursion" (function()
  local dsl_loader = make_dsl_loader(simple_name_filter)
  local api = dsl_loader:get_interface()

  local t = { }
  t[t] = t

  ensure_fails_with_substring(
      "recursion is detected",
      function()
        dsl_loader:finalize_data(api:foo "alpha" { t })
      end,
      "recursion detected"
    )
end)

--------------------------------------------------------------------------------

test:BROKEN_IF(is_lua52_or_lua53) "filters-basic" (function()
  local NAME_PREFIX = "N-"
  local NAME_VALUE = "MYNAMEVALUE"
  local DATA_VALUE = "MYDATAVALUE"

  local name_calls = { }
  local data_calls = { }

  local name_filter = function(tag_value, name_value, ...)
    ensure_equals("no extra arguments", select("#", ...), 0)
    -- Name calls must be ordered by appearance.
    name_calls[#name_calls + 1] = { tag = tag_value, name = name_value }

    return
    {
      [TAG] = tag_value;
      [NAME] = NAME_PREFIX .. name_value;
      NAME_KEY = NAME_VALUE;
    }
  end

  local data_filter = function(name_data, value_data)
    local data = tappend_many(name_data, value_data)

    -- Data calls order is undefined.
    data_calls[{ data = data }] = true

    local result = tclone(data)
    result.DATA_KEY = DATA_VALUE

    return result
  end

  local dsl_loader = make_dsl_loader(name_filter, data_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "collected data check",
      dsl_loader:finalize_data(
          {
            api:alpha "one";
            api:beta "two"
            {
              api:gamma "three"
              {
                value = 1;
              };
            };
          }
        ),
      {
        {
          [TAG] = "alpha";
          [NAME] = NAME_PREFIX .. "one";
          NAME_KEY = NAME_VALUE;
          DATA_KEY = DATA_VALUE;
        };

        {
          [TAG] = "beta";
          [NAME] = NAME_PREFIX .. "two";
          NAME_KEY = NAME_VALUE;
          DATA_KEY = DATA_VALUE;

          {
            [TAG] = "gamma";
            [NAME] = NAME_PREFIX .. "three";
            NAME_KEY = NAME_VALUE;
            DATA_KEY = DATA_VALUE;
            value = 1;
          };
        };
      }
    )

  ensure_tdeepequals(
      "name calls check",
      name_calls,
      {
        { tag = "alpha", name = "one" };
        { tag = "beta", name = "two" };
        { tag = "gamma", name = "three" };
      }
    )

  ensure_tdeepequals(
      "data calls check",
      data_calls,
      tset
      {
        {
          data =
          {
            [TAG] = "alpha", [NAME] = NAME_PREFIX .. "one";
            NAME_KEY = NAME_VALUE;
          }
        };
        {
          data =
          {
            [TAG] = "gamma", [NAME] = NAME_PREFIX .. "three", value = 1;
            NAME_KEY = NAME_VALUE;
          };
        };
        {
          data =
          {
            [TAG] = "beta", [NAME] = NAME_PREFIX .. "two";
            NAME_KEY = NAME_VALUE;
            {
              [TAG] = "gamma", [NAME] = NAME_PREFIX .. "three";
              NAME_KEY = NAME_VALUE;
              DATA_KEY = DATA_VALUE;
              value = 1;
            };
          };
        };
      }
    )
end)

--------------------------------------------------------------------------------

test:BROKEN_IF(is_lua52_or_lua53) "finalize_data-multiapi" (function()
  local tags_1 = tset { "alpha", "gamma", "epsilon" }
  local names_1 = tset { "one", "three", "five" }

  local TAG_1, NAME_1 = "xTAG_1x", "xNAME_1x"

  local name_filter_1 = function(tag_value, name_value, ...)
    ensure_equals("no extra arguments", select("#", ...), 0)

    assert(tags_1[tag_value])
    assert(names_1[name_value])

    return
    {
      [TAG_1] = tag_value;
      [NAME_1] = name_value;
    }
  end

  local data_filter_1 = function(name_data, value_data)
    local data = tappend_many(name_data, value_data)

    assert(
        tags_1[assert(data[TAG_1])]
      )

    assert(
        names_1[assert(data[NAME_1])]
      )

    return data
  end

  local dsl_loader_1 = make_dsl_loader(name_filter_1, data_filter_1)
  local api_1 = dsl_loader_1:get_interface()

  local tags_2 = tset { "beta", "delta" }
  local names_2 = tset { "two", "four" }

  local TAG_2, NAME_2 = "xTAG_2x", "xNAME_2x"

  local name_filter_2 = function(tag_value, name_value, ...)
    ensure_equals("no extra arguments", select("#", ...), 0)

    assert(tags_2[tag_value])
    assert(names_2[name_value])

    return
    {
      [TAG_2] = tag_value;
      [NAME_2] = name_value;
    }
  end

  local data_filter_2 = function(name_data, value_data)
    local data = tappend_many(name_data, value_data)

    assert(
        tags_2[assert(data[TAG_2])]
      )

    assert(
        names_2[assert(data[NAME_2])]
      )

    return data
  end

  local dsl_loader_2 = make_dsl_loader(name_filter_2, data_filter_2)
  local api_2 = dsl_loader_2:get_interface()

  local gen_data = function()
    return api_1:alpha "one"
    {
      api_2:beta "two"
      {
        api_1:gamma "three"
        {
          value = 42;
          api_2:delta "four";
        };
        api_1:epsilon "five";
      };
    }
  end

  local expected =
  {
    [TAG_1] = "alpha";
    [NAME_1] = "one";

    {
      [TAG_2] = "beta";
      [NAME_2] = "two";

      {
        [TAG_1] = "gamma";
        [NAME_1] = "three";
        value = 42;

        {
          [TAG_2] = "delta";
          [NAME_2] = "four";
        }
      };

      {
        [TAG_1] = "epsilon";
        [NAME_1] = "five";
      }
    };
  }

  ensure_tdeepequals(
      "check finalized data 1(2)",
      dsl_loader_1:finalize_data(
          dsl_loader_2:finalize_data(
              gen_data()
            )
        ),
      expected
    )

  ensure_tdeepequals(
      "check finalized data 2(1)",
      dsl_loader_2:finalize_data(
          dsl_loader_1:finalize_data(
              gen_data()
            )
        ),
      expected
    )
end)

--------------------------------------------------------------------------------

-- Based on actual bug scenario
test:BROKEN_IF(is_lua52_or_lua53) "finalize_data-finalize-name-data" (function()
  local name_filter = function(tag, name, ...)
    assert(select("#", ...) == 0, "extra arguments are not supported")

    return
    {
      [TAG] = tag;
      [NAME] = name; -- Ignoring that name may be a table
    }
  end

  local data_filter = function(name_data, value_data)
    -- Letting user to override any default values (including name and tag)
    return twithdefaults(value_data, name_data)
  end

  local dsl_loader = make_dsl_loader(name_filter, data_filter)
  local api = dsl_loader:get_interface()

  ensure_tdeepequals(
      "full returned value check",
      dsl_loader:finalize_data(
          api:alpha
          {
            api:beta "two" { };
          }
        ),
      {
        [TAG] = "alpha";
        [NAME] =
        {
          {
            [TAG] = "beta";
            [NAME] = "two";
          };
        };
      }
    )

  ensure_tdeepequals(
      "name-only returned value check",
      dsl_loader:finalize_data(
          api:alpha
          {
            api:beta "two";
          }
        ),
      {
        [TAG] = "alpha";
        [NAME] =
        {
          {
            [TAG] = "beta";
            [NAME] = "two";
          };
        };
      }
    )
end)
