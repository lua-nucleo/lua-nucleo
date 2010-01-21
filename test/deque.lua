-- deque.lua: tests for double-ended queue wrapper
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

math.randomseed(12345)

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_tdeepequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_tdeepequals',
        'ensure_fails_with_substring'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local tset,
      tclone,
      empty_table,
      tstr
      = import 'lua-nucleo/table.lua'
      {
        'tset',
        'tclone',
        'empty_table',
        'tstr'
      }

local make_value_generators
      = import 'test/lib/value_generators.lua'
      {
        'make_value_generators'
      }

--------------------------------------------------------------------------------

local make_deque,
      deque_exports
      = import 'lua-nucleo/deque.lua'
      {
        'make_deque'
      }

--------------------------------------------------------------------------------

local test = make_suite("deque", deque_exports)

--------------------------------------------------------------------------------

test:factory "make_deque" ((function()
  return debug.getmetatable(make_deque()).__index -- TODO: Hack
end))

test:methods "back"
             "pop_back"
             "push_back"
             "front"
             "pop_front"
             "push_front"
             "size"

--------------------------------------------------------------------------------

test "deque-empty-size" (function()
  local deque = make_deque()
  ensure_equals("size", deque:size(), 0)
end)

test "deque-empty-back" (function()
  local deque = make_deque()
  ensure_equals("back", deque:back(), nil)
end)

test "deque-empty-front" (function()
  local deque = make_deque()
  ensure_equals("front", deque:front(), nil)
end)

test "deque-empty-pop_back" (function()
  local deque = make_deque()
  ensure_equals("pop_back", deque:pop_back(), nil)
end)

test "deque-empty-pop_front" (function()
  local deque = make_deque()
  ensure_equals("pop_front", deque:pop_front(), nil)
end)

test "deque-empty-push-pop-back" (function()
  local deque = make_deque()

  deque:push_back(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("pop back", deque:pop_back(), 42)

  ensure_equals("size empty", deque:size(), 0)
  ensure_equals("back empty", deque:back(), nil)
  ensure_equals("front empty", deque:front(), nil)
end)

test "deque-empty-push-pop-front" (function()
  local deque = make_deque()

  deque:push_front(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("pop front", deque:pop_front(), 42)

  ensure_equals("size empty", deque:size(), 0)
  ensure_equals("back empty", deque:back(), nil)
  ensure_equals("front empty", deque:front(), nil)
end)

test "deque-empty-push-back-pop-front" (function()
  local deque = make_deque()

  deque:push_back(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("pop front", deque:pop_front(), 42)

  ensure_equals("size empty", deque:size(), 0)
  ensure_equals("back empty", deque:back(), nil)
  ensure_equals("front empty", deque:front(), nil)
end)

test "deque-empty-push-front-pop-back" (function()
  local deque = make_deque()

  deque:push_front(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("pop back", deque:pop_back(), 42)

  ensure_equals("size empty", deque:size(), 0)
  ensure_equals("back empty", deque:back(), nil)
  ensure_equals("front empty", deque:front(), nil)
end)

test "deque-empty-over-pop_front" (function()
  local deque = make_deque()

  ensure_equals("pop front 1", deque:pop_front(), nil)
  ensure_equals("pop front 2", deque:pop_front(), nil)
  ensure_equals("pop front 3", deque:pop_front(), nil)

  deque:push_front(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)
end)

test "deque-empty-over-pop_back" (function()
  local deque = make_deque()

  ensure_equals("pop back 1", deque:pop_back(), nil)
  ensure_equals("pop back 2", deque:pop_back(), nil)
  ensure_equals("pop back 3", deque:pop_back(), nil)

  deque:push_back(42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)
end)

--------------------------------------------------------------------------------

test "deque-wraps-data" (function()
  local t = { 42 }

  local deque = make_deque(t)

  ensure_equals("deque wraps data", deque, t) -- Direct equality

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("size", deque:size(), 1)
  ensure_equals("back", deque:back(), 42)
  ensure_equals("front", deque:front(), 42)

  ensure_equals("pop back", deque:pop_back(), 42)

  ensure_equals("size empty", deque:size(), 0)
  ensure_equals("back empty", deque:back(), nil)
  ensure_equals("front empty", deque:front(), nil)
end)

--------------------------------------------------------------------------------

test "deque-empty-push_back-nil-fails" (function()
  local deque = make_deque()
  ensure_fails_with_substring(
      "push_back nil",
      function() deque:push_back(nil) end,
      "deque: can't push nil"
    )
end)

test "deque-empty-pop_back-nil-fails" (function()
  local deque = make_deque()
  ensure_fails_with_substring(
      "push_back nil",
      function() deque:push_back(nil) end,
      "deque: can't push nil"
    )
end)

test "deque-empty-pre-set-back" (function()
  -- A semi-official side effect.
  local deque = make_deque({ [0] = "EMPTY" })

  ensure_equals("empty size", deque:size(), 0)
  ensure_equals("empty back", deque:back(), nil)
  ensure_equals("empty pop_back", deque:pop_back(), nil)

  deque:push_back(42)

  ensure_equals("non-empty size", deque:size(), 1)
  ensure_equals("non-empty back", deque:size(), 1)

  ensure_equals("pop_back", deque:pop_back(), 42)

  ensure_equals("empty size again", deque:size(), 0)
  ensure_equals("empty back again", deque:back(), nil)

  ensure_equals("zero is still there", deque[0], "EMPTY")
end)

test "deque-on-metatable-fails" (function()
  local data = setmetatable({ }, { })
  ensure_fails_with_substring(
      "push_back nil",
      function() make_deque(data) end,
      "can't create deque on data with metatable"
    )
end)

--------------------------------------------------------------------------------

test "deque-random" (function()
  local NUM_ITER = 1e4
  local MAX_NUM_OPERATIONS = 1e2
  local MAX_INITIAL_SIZE = 1e3

  local value_generators = make_value_generators(tset({ "userdata" }))
  local random_value = function()
    return value_generators[math.random(#value_generators)]()
  end

  -- Not using numeric keys in hash part to avoid confusing #t
  local key_generators = make_value_generators(
      tset({ "userdata", "no-numbers" })
    )
  local random_key = function()
    return key_generators[math.random(#key_generators)]()
  end

  local check_once = function()
    local initial_data = nil

    if math.random() > 0.5 then
      -- print("using empty initial data")
    else
      -- print("using non-empty initial data")

      initial_data = { }

      for i = 1, math.random(MAX_INITIAL_SIZE) do
        if math.random() > 0.25 then
          -- Array part
          initial_data[#initial_data + 1] = random_value()
        else
          -- Hash part
          initial_data[random_key()] = random_value()
        end
      end
    end

    local expected = { }
    for k, v in pairs(initial_data or empty_table) do
      -- Note can't use tclone(), need shallow copy.
      expected[k] = v
    end

    local deque = make_deque(initial_data)

    local check_ends = function(deque, expected)
      local expected_size = #expected
      local expected_back = expected[expected_size]
      if expected_size == 0 then
        expected_back = nil
      end
      local expected_front = expected[1]

      ensure_equals("size", deque:size(), expected_size)
      ensure_equals("back", deque:back(), expected_back)
      ensure_equals("front", deque:front(), expected_front)

      return expected_size, expected_back, expected_front
    end

    local operations =
    {
      -- Push back
      function(deque, expected)
        local size, back, front = check_ends(deque, expected)

        local value = random_value()
        deque:push_back(value)

        expected[#expected + 1] = value

        check_ends(deque, expected)
      end;
      -- Push front
      function(deque, expected)
        local size, back, front = check_ends(deque, expected)

        local value = random_value()
        deque:push_front(value)

        table.insert(expected, 1, value)

        check_ends(deque, expected)
      end;
      -- Pop back
      function(deque, expected)
        local size, back, front = check_ends(deque, expected)

        --print("BEFORE POP deque   ", tstr(deque))
        --print("BEFORE POP expected", tstr(expected))

        ensure_equals("sanity check", table.remove(expected), back)
        ensure_equals("pop_back", deque:pop_back(), back)

        check_ends(deque, expected)
      end;
      -- Pop front
      function(deque, expected)
        local size, back, front = check_ends(deque, expected)

        ensure_equals("sanity check", table.remove(expected, 1), front)
        ensure_equals("pop_front", deque:pop_front(), front)

        check_ends(deque, expected)
      end;
    }

    check_ends(deque, expected)
    for i = 1, math.random(MAX_NUM_OPERATIONS) do
      operations[math.random(#operations)](deque, expected)
    end
    check_ends(deque, expected)
  end

  for i = 1, NUM_ITER do
    if i % 1000 == 0 then
      print("deque check", i, "of", NUM_ITER)
    end
    check_once()
  end
end)

--------------------------------------------------------------------------------

assert(test:run())
