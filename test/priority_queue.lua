-- priority_queue.lua: tests for priority queue
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Add tests for invalid priority
-- TODO: Refactor and extend tests for many objects
-- TODO: Test on 'nil' object to be inserted???

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local assert_is_table,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_number'
      }

local ensure,
      ensure_equals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring'
      }

local tdeepequals,
      tstr
      = import 'lua-nucleo/table.lua'
      {
        'tdeepequals',
        'tstr'
      }

local make_priority_queue,
      priority_queue_exports
      = import 'lua-nucleo/priority_queue.lua'
      {
        'make_priority_queue'
      }

--------------------------------------------------------------------------------

local test = make_suite("priority_queue", priority_queue_exports)

local check_insert_pop_elements = function(priority_queue, elements)
  ensure_equals("no first before element", priority_queue:front(), nil);

  for _,v in ipairs(elements) do
    priority_queue:insert(v.p, v.v);
  end

  -- TODO: Sort elements somehow
  local sorted_elements = elements

  for i = 1, #sorted_elements do
    local popped_priority, popped_value = priority_queue:pop();
    ensure_equals("popped priority " .. i, popped_priority, sorted_elements[i].p);
    ensure_equals("popped value " .. i, popped_value, sorted_elements[i].v);
  end

  ensure_equals("no first after element", priority_queue:front(), nil);
end

--------------------------------------------------------------------------------

test:group "make_priority_queue"

--------------------------------------------------------------------------------

test "empty" (function()
  local priority_queue = make_priority_queue()
  ensure("created priority queue", priority_queue)

  ensure_equals("no first element", priority_queue:front(), nil);
end)

--------------------------------------------------------------------------------

test "single-element" (function()
  local priority_queue = assert_is_table(make_priority_queue())
  check_insert_pop_elements(priority_queue, {{p = 42, v = function() end}})
end)

--------------------------------------------------------------------------------

test "single-invalid-priority-type" (function()
  local priority_queue = assert_is_table(make_priority_queue())

  local value = 42

  ensure_fails_with_substring(
      "priority cannot be of 'nil' type",
      function() priority_queue:insert(nil, value) end,
      "expected `number', got `nil'"
    )

  ensure_fails_with_substring(
      "priority cannot be of 'string' type",
      function() priority_queue:insert("the string", value) end,
      "expected `number', got `string'"
    )

  ensure_fails_with_substring(
      "priority cannot be of 'table' type",
      function() priority_queue:insert({}, value) end,
      "expected `number', got `table'"
    )

  ensure_fails_with_substring(
      "priority cannot be of 'function' type",
      function() priority_queue:insert(function() end, value) end,
      "expected `number', got `function'"
    )

end)

--------------------------------------------------------------------------------

test "two-elements" (function()
  local priority_queue = assert_is_table(make_priority_queue())

  local elements =
  {
    { p = 1, v = 322} ;
    { p = 2, v = "v" };
    { p = 3, v = function() end };
    { p = 4, v = {} };
  }

  check_insert_pop_elements(priority_queue, elements)
end)

--------------------------------------------------------------------------------

assert(test:run())
