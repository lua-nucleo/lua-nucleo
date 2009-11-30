-- priority_queue.lua: tests for priority queue
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

math.randomseed(12345)
--math.randomseed(os.time())

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local assert_is_table,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_number'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local tstr,
      tclone,
      tgenerate_n,
      tequals
      = import 'lua-nucleo/table.lua'
      {
        'tstr',
        'tclone',
        'tgenerate_n',
        'tequals'
      }

local invariant,
      make_generator_mt
      = import 'lua-nucleo/functional.lua'
      {
        'invariant',
        'make_generator_mt'
      }

local make_priority_queue,
      priority_queue_exports
      = import 'lua-nucleo/priority_queue.lua'
      {
        'make_priority_queue'
      }

--------------------------------------------------------------------------------

local test = make_suite("priority_queue", priority_queue_exports)

local check_insert_pop_elements = function(elements)
  arguments(
      "table", elements
    )

  elements = tclone(elements)

  local priority_queue = ensure("created priority queue", make_priority_queue())

  -- Separate queue to ensure front does not affect pop.
  local priority_queue_2 = ensure("created priority queue 2", make_priority_queue())

  ensure_equals("no first before element", priority_queue:front(), nil)

  print("Building queues")

  for i = 1, #elements do
    if i % 1000 == 0 then
      print(i, "of", #elements)
    end

    local v = elements[i]
    priority_queue:insert(v.p, v.v)
    priority_queue_2:insert(v.p, v.v)
  end

  print("Sorting elements")

  table.sort(elements, function(lhs, rhs) return lhs.p < rhs.p end)

  print("Detecting duplicates")

  local element_counts = setmetatable(
      { },
      make_generator_mt(function()
        return setmetatable(
            { },
            make_generator_mt(invariant(0))
          )
      end)
    )

  for i = 1, #elements do
    if i % 1000 == 0 then
      print(i, "of", #elements)
    end

    local priority_element_counts = element_counts[elements[i].p]
    priority_element_counts[elements[i].v] = priority_element_counts[elements[i].v] + 1
  end

  print("Popping")

  for i = 1, #elements do
    if i % 1000 == 0 then
      print(i, "of", #elements)
    end

    local front = { priority_queue_2:front() }
    local popped = { priority_queue:pop() }

    ensure_tequals("pop2 " .. i, { priority_queue_2:pop() }, front)

    ensure_tequals("front matches popped " .. i, front, popped)

    local expected = { elements[i].p, elements[i].v }
    local popped_p, popped_v = unpack(popped)
    local expected_p = unpack(expected)

    local handled_duplicate = false
    if popped_p == expected_p then
      local priority_element_counts = element_counts[popped_p]
      if priority_element_counts[popped_v] > 0 then
        priority_element_counts[popped_v] = priority_element_counts[popped_v] - 1
        handled_duplicate = true
      else
        -- Would be handled in the check below
        print("unexpected element", popped_v, "for priority", popped_p)
      end
    end

    if not handled_duplicate then
      ensure_tequals( -- Would fail. It is here for consistent error message.
          "popped priority " .. i,
          popped,
          expected
        )
    end
  end

  ensure_equals("no first after element", priority_queue:front(), nil)

  for p, priority_element_counts in pairs(element_counts) do
    for v, count in pairs(priority_element_counts) do
      if count ~= 0 then
        error(
            "detected unhandled elements"
         .. " p: " .. tostring(p)
         .. " v: " .. tostring(v)
         .. " count: " .. tostring(count)
          )
      end
    end
  end

  print("Done")
end

--------------------------------------------------------------------------------

test:group "make_priority_queue"

--------------------------------------------------------------------------------

test "empty" (function()
  local priority_queue = make_priority_queue()
  ensure("created priority queue", priority_queue)

  ensure_equals("no first element", priority_queue:front(), nil)
end)

--------------------------------------------------------------------------------

test "empty-pop" (function()
  local priority_queue = make_priority_queue()
  ensure("created priority queue", priority_queue)

  ensure_equals("no first element", priority_queue:front(), nil)
  ensure_equals("pop on empty queue", priority_queue:pop(), nil)
  priority_queue:insert(1, "1")
  ensure_tequals(
      "pop on non-empty queue",
      { priority_queue:pop() },
      { 1, "1" }
    )
  ensure_equals("pop on empty queue again", priority_queue:pop(), nil)
end)

--------------------------------------------------------------------------------

test "insert-pop-insert" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())
  ensure_equals("no first element", priority_queue:front(), nil)

  priority_queue:insert(2, "2")
  priority_queue:insert(1, "1")

  priority_queue:insert(priority_queue:pop())

  print(tstr(priority_queue.queue_))

  ensure_tequals("pop 2", { priority_queue:pop() }, { 1, "1" })
  ensure_tequals("pop 1", { priority_queue:pop() }, { 2, "2" })

  ensure_tequals("empty", { priority_queue:pop() }, { nil })
end)

--------------------------------------------------------------------------------

test "single-element" (function()
  check_insert_pop_elements({{p = 42, v = function() end}})
end)

--------------------------------------------------------------------------------

test "single-invalid-priority-type" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())

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

  ensure_fails_with_substring(
      "priority cannot be of 'coroutine' type",
      function() priority_queue:insert(coroutine.create(function() end), value) end,
      "expected `number', got `thread'"
    )

  ensure_fails_with_substring(
      "priority cannot be of 'userdata' type",
      function() priority_queue:insert(newproxy(), value) end,
      "expected `number', got `userdata'"
    )
end)

--------------------------------------------------------------------------------

test "insert_nil_fails" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())
  ensure_fails_with_substring(
      "can't insert nil",
      function() priority_queue:insert(1, nil) end,
      "value can't be nil"
    )
end)

test "many-elements-direct" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())

  local elements =
  {
    { p = 1, v = 322 };
    { p = 2, v = "v" };
    { p = 3, v = function() end };
    { p = 4, v = {} };
  }

  check_insert_pop_elements(elements)
end)

test "many-elements-reversed" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())

  local elements =
  {
    { p = 4, v = {} };
    { p = 3, v = function() end };
    { p = 2, v = "v" };
    { p = 1, v = 322 };
  }

  check_insert_pop_elements(elements)
end)

test "many-elements-random-hardcoded" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())

  local elements =
  {
    { p = 2, v = "v" };
    { p = 3, v = function() end };
    { p = 1, v = 322 };
    { p = 4, v = {} };
  }

  check_insert_pop_elements(elements)
end)

test "many-elements-random-generated" (function()
  local priority_queue = ensure("created priority queue", make_priority_queue())

  local value_generators = -- TODO: Generalize to test-lib (let user to select features, like nil, NaN etc.)
  {
    --invariant(nil);
    -- No nil data here to extend applicability
    invariant(true);
    invariant(false);
    invariant(-42);
    invariant(-1);
    invariant(0);
    math.random;
    function() return math.random(-1e8, 1e8) end;
    invariant(1);
    invariant(42);
    invariant(math.pi);
    -- No NaN data here to extend applicability
    invariant(1/0);
    invariant(-1/0);
    invariant("");
    invariant("The Answer to the Ultimate Question of Life, the Universe, and Everything");
    invariant("embedded\0zero");
    invariant("multiline\nstring");
    -- TODO: Random_string().
    invariant({});
    invariant({ 1 });
    invariant({ a = 1 });
    invariant({ a = 1; 1 });
    invariant({ [{}] = {} });
    -- No recursive data here to extend applicability
    invariant(function() end);
    -- No functions with upvalues to extend applicability
    invariant(coroutine.create(function() end));
    invariant(newproxy());
  }

  local MIN_ELEMENTS = 0
  local MAX_ELEMENTS = 1e4

  local MIN_PRIORITY = 0
  local MAX_PRIORITY = 1e3

  local elements = tgenerate_n(
      math.random(MIN_ELEMENTS, MAX_ELEMENTS),
      function()
        return
        {
          p = math.random(MIN_PRIORITY, MAX_PRIORITY);
          v = value_generators[math.random(#value_generators)]();
        }
      end
    )

  check_insert_pop_elements(elements)
end)

--------------------------------------------------------------------------------

assert(test:run())
