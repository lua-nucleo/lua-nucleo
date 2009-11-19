-- log.lua: tests for logging system
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

--------------------------------------------------------------------------------

local assert_is_string,
      assert_is_table,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_string',
        'assert_is_table',
        'assert_is_function'
      }

local ensure,
      ensure_equals,
      ensure_strequals,
      ensure_tequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals',
        'ensure_tequals',
        'ensure_fails_with_substring'
      }

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

--------------------------------------------------------------------------------

local LOG_LEVEL,
      END_OF_LOG_MESSAGE,
      format_logsystem_date,
      get_current_logsystem_date,
      make_logging_system,
      wrap_file_sink,
      create_common_logging_system,
      get_common_logging_system,
      make_loggers,
      log_exports
      = import 'lua-nucleo/log.lua'
      {
        'LOG_LEVEL',
        'END_OF_LOG_MESSAGE',
        'format_logsystem_date',
        'get_current_logsystem_date',
        'make_logging_system',
        'wrap_file_sink',
        'create_common_logging_system',
        'get_common_logging_system',
        'make_loggers'
      }

--------------------------------------------------------------------------------

local test = make_suite("log", log_exports)

--------------------------------------------------------------------------------

test:test_for "LOG_LEVEL" (function()
  assert_is_table(LOG_LEVEL) -- Smoke test
end)

test:test_for "END_OF_LOG_MESSAGE" (function()
  assert_is_string(END_OF_LOG_MESSAGE) -- Smoke test, arbitrary limit
end)

--------------------------------------------------------------------------------

test:test_for "format_logsystem_date" (function()
  ensure_strequals(
      "format_logsystem_date",
      format_logsystem_date(0),
      os.date("%Y-%m-%d %H:%M:%S", 0) -- Silly smoke test
    )
end)

test:test_for "get_current_logsystem_date" (function()
  local ts_before = 0
  local ts_after = nil
  local formatted_date

  -- We should get time inside one second
  -- to avoid false positives in check below
  local n = 0
  while ts_before ~= ts_after do -- Assuming integer seconds
    ts_before = os.time()
    formatted_date = get_current_logsystem_date()
    ts_after = os.time()
    n = n + 1
    assert(n < 10, "infinite loop detected")
  end

  ensure_strequals(
      "get_current_logsystem_date",
      formatted_date,
      os.date("%Y-%m-%d %H:%M:%S", ts_after)
    )
end)

--------------------------------------------------------------------------------

test:test_for "wrap_file_sink" (function()
  local flush_tag = unique_object()

  local buf = {}

  local file_mock =
  {
    write = function(self, v)
      method_arguments(
          self,
          "string", v
        )
      buf[#buf + 1] = v
    end;

    flush = function(self)
      method_arguments(
          self
        )
      buf[#buf + 1] = flush_tag
    end;
  }

  local sink = assert_is_function(wrap_file_sink(file_mock))

  ensure_equals("aaa", sink("aaa"), sink)
  ensure_equals("flush", sink(END_OF_LOG_MESSAGE), sink)
  ensure_equals("bbb", sink("bbb"), sink)

  ensure_tequals(
      "call order check",
      buf,
      { "aaa", END_OF_LOG_MESSAGE, flush_tag, "bbb" }
    )
end)

--------------------------------------------------------------------------------

assert(test:run())
