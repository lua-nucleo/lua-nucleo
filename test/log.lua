-- log.lua: tests for logging system
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

--------------------------------------------------------------------------------

local assert_is_string,
      assert_is_table,
      assert_is_nil,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_string',
        'assert_is_table',
        'assert_is_nil',
        'assert_is_function'
      }

local tstr,
      tstr_cat,
      tcount_elements,
      tijoin_many,
      tclone,
      tset
      = import 'lua-nucleo/table.lua'
      {
        'tstr',
        'tstr_cat',
        'tcount_elements',
        'tijoin_many',
        'tclone',
        'tset'
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

local make_concatter = import 'lua-nucleo/string.lua' { 'make_concatter' }

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

test:tests_for 'create_common_logging_system'
               'get_common_logging_system'

-- WARNING: We're creating singleton here. DO NOT use it in other tests!
-- TODO: Isolate this somehow!
test:test "create-and-get-common-logging-system" (function()
  local cat, concat = make_concatter()
  local logging_system = create_common_logging_system(
      "{logger_id} ",
      cat
      -- TODO: Add default arguments as well
    )
  assert_is_table(get_common_logging_system())
  -- TODO: Check logging system received all arguments from
  --       create_common_logging_system
end)

--------------------------------------------------------------------------------

test:group "make_logging_system"

--------------------------------------------------------------------------------

-- TODO: Generalize
local make_test_concatter = function()
  local concatter =
  {
    buf_ = { };
  }

  concatter.cat = function(v)
    local buf = concatter.buf_
    buf[#buf + 1] = assert_is_string(v)
    return concatter.cat
  end

  concatter.reset = function()
    concatter.buf_ = { }
  end

  concatter.buf = function()
    return tclone(concatter.buf_)
  end

  return concatter
end

local check_date_str = function(date_str, time_before, time_after)
  arguments(
      "string", date_str,
      "number", time_before,
      "number", time_after
    )

  assert(time_before <= time_after)

  local t = {}
  t.year, t.month, t.day,
  t.hour, t.min, t.sec = date_str:match(
      "^(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)$"
    )

  local timestamp = ensure("time format valid", os.time(t))

  ensure("time after before", time_before <= timestamp)
  ensure("time before after", timestamp >= time_after)
end

local check_logger = function(
    concatter,
    logger,
    logging_system_id,
    module_suffix,
    ...
  )
  arguments(
         "table", concatter,
      "function", logger,
        "string", logging_system_id,
        "string", module_suffix
    )

  concatter.reset()

  local ts_before = os.time()
  logger(...)
  local ts_after = os.time()

  local actual = concatter.buf()

  -- Prepend system info to expected data
  local date = assert_is_string(actual[2])
  check_date_str(date, ts_before, ts_after)

  local expected = { "[", date, "] ", logging_system_id, "[", module_suffix, "] " }

  local function expected_cat(v)
    expected[#expected + 1] = assert_is_string(v)
    return expected_cat
  end

  for i = 1, select("#", ...) do
    local v = select(i, ...)

    if i > 1 then
      expected_cat(" ")
    end

    if is_table(v) then
      tstr_cat(expected_cat, v)
    else
      expected_cat(tostring(v))
    end
  end

  expected_cat(END_OF_LOG_MESSAGE)

  --print("  actual", tstr(actual))
  --print("expected", tstr(expected))
  ensure_tequals("check_logger", actual, expected)

  concatter.reset()
end

local check_make_module_logger = function(
    concatter,
    logging_system,
    logging_system_id,
    ...
  )
  for _, log_level in pairs(LOG_LEVEL) do
    local logger = ensure(
        "make_module_logger",
        logging_system:make_module_logger(
            "module_name", log_level, "MOD"
          )
      )

    check_logger(
        concatter, logger,
        logging_system_id, "MOD",
        ...
      )
  end
end

--------------------------------------------------------------------------------

test "make_module_logger-empty" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(logging_system_id, concatter.cat, tset(LOG_LEVEL))
    )

  check_make_module_logger(
      concatter, logging_system, logging_system_id
      -- Empty
    )
end)

test "make_module_logger-simple" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(logging_system_id, concatter.cat, tset(LOG_LEVEL))
    )

  check_make_module_logger(
      concatter, logging_system, logging_system_id,
      42, "embedded\0zero", nil, true, nil
    )
end)

test "make_module_logger-table" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(logging_system_id, concatter.cat, tset(LOG_LEVEL))
    )

  check_make_module_logger(
      concatter, logging_system, logging_system_id,
      nil, { [{ 42, nil, 24 }] = { a = 42 } }, nil
    )
end)

--------------------------------------------------------------------------------
--[=[
test "all-logging-levels-disabled-by-default" (function()
  local cat, concat = make_concatter()

  local logging_system = make_logging_system("the logger", cat)

  for _, v in pairs(LOG_LEVEL) do
    ensure(
        "logging for module is disabled",
        logging_system:is_log_enabled("the module", v) == false
      )
  end
end)

test "all-logging-levels-enabled-and-enabled-for-module-by-default" (function()
  local cat, concat = make_concatter()

  local levels_config =
  {
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
    [LOG_LEVEL.ERROR] = true;
  }

  local logging_system = make_logging_system("the logger", cat, levels_config)

  for _, v in pairs(LOG_LEVEL) do
    ensure(
        "logging for module is enabled",
        logging_system:is_log_enabled("the module", v)
      )
  end
end)

test "all-loggers-enabled-but-disabled-for-module" (function()
  local cat, concat = make_concatter()

  local levels_config =
  {
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
    [LOG_LEVEL.ERROR] = true;
  }

  local module_config =
  {
    ["the module"] =
    {
      [LOG_LEVEL.LOG]   = false;
      [LOG_LEVEL.DEBUG] = false;
      [LOG_LEVEL.SPAM]  = false;
      [LOG_LEVEL.ERROR] = false;
    }
  }

  local logging_system = make_logging_system("the logger", cat, levels_config, module_config)

  for _, v in pairs(LOG_LEVEL) do
    ensure(
        "logging for module is ",
        logging_system:is_log_enabled("the module", v) == false
      )
  end
end)

--------------------------------------------------------------------------------

test:test_for "make_loggers" (function()
  local cat, concat = make_concatter()

  local levels_config =
  {
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
    [LOG_LEVEL.ERROR] = true;
  }

  local logging_system = make_logging_system("the logger", cat, levels_config)

  local loggers = { make_loggers("the module", "the module prefix", nil, logging_system) }
  assert(#loggers == tcount_elements(LOG_LEVEL))
  for _, logger in ipairs(loggers) do
    assert_is_function(logger)
  end
end)

--------------------------------------------------------------------------------

local check_loggers_output = function(loggers, concatter, ...)
  arguments(
      "table",  loggers,
      "table",  concatter
    )

  local check_output = function(output, ...)
    local nargs = select("#", ...)

    --print("output>>>>>>>", tstr(output))

    ensure("open sqrbr of date ", concatter.buffer[1] == "[")
    --TODO: Check data is string?
    ensure("close sqrbr of date ", concatter.buffer[3] == "] ")

    ensure("open sqrbr of module ", concatter.buffer[4] == "[")
    --TODO: Check module name
    ensure("close sqrbr of module ", concatter.buffer[6] == "] ")

    for i = 1, nargs do
      local arg = select(i, ...)

      if is_table(arg) then
        ensure("cat table argument " .. i, concatter.buffer[5 + i*2] == tstr(arg))
      else
        ensure("cat argument " .. i, concatter.buffer[5 + i*2] == tostring(arg))
      end

      if i < nargs then
        ensure("close sqrbr of module ", concatter.buffer[5 + i*2 + 1] == " ")
      end
    end

    local suffix_start_pos = 5 + nargs*2 + 1
    ensure("end of log message", concatter.buffer[suffix_start_pos] == END_OF_LOG_MESSAGE)
  end


  for _, logger in ipairs(loggers) do
    concatter.buffer = {}

    logger(...)

    --TODO: Make right 'expected'
    check_output(concatter.buffer, ...)
  end

end

test:test "log-string-and-number-and-nil" (function()
  local concatter =
  {
    buffer = {}
  }
  concatter.cat = function(v)
    concatter.buffer[#concatter.buffer + 1] = v
    return concatter.cat
  end

  local levels_config =
  {
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
    [LOG_LEVEL.ERROR] = true;
  }

  local logging_system = make_logging_system("the logger", concatter.cat, levels_config)

  local loggers = { make_loggers("the module", "the module prefix", nil, logging_system) }

  check_loggers_output(loggers, concatter, "the string", 0, 1, nil, 42)
end)

test:test "log-table" (function()
  local concatter =
  {
    buffer = {}
  }
  concatter.cat = function(v)
    concatter.buffer[#concatter.buffer + 1] = v
    return concatter.cat
  end

  local levels_config =
  {
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
    [LOG_LEVEL.ERROR] = true;
  }

  local logging_system = make_logging_system("the logger", concatter.cat, levels_config)

  local loggers = { make_loggers("the module", "the module prefix", nil, logging_system) }

  check_loggers_output(
      loggers,
      concatter,
      {"first", 42},
      { key1 = "value"; key2 = 420 }
    )
end)
--]=]

--------------------------------------------------------------------------------

assert(test:run())
