-- log.lua: tests for logging system
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

--------------------------------------------------------------------------------

local is_string,
      is_function
      = import 'lua-nucleo/type.lua'
      {
        'is_string',
        'is_function'
      }

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
      make_common_logging_config,
      make_logging_system,
      wrap_file_sink,
      make_loggers,
      log_exports
      = import 'lua-nucleo/log.lua'
      {
        'LOG_LEVEL',
        'END_OF_LOG_MESSAGE',
        'format_logsystem_date',
        'get_current_logsystem_date',
        'make_common_logging_config',
        'make_logging_system',
        'wrap_file_sink',
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

test:factory "make_logging_system" (
    make_logging_system, "", function() end, {}
  )

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
    date_checker,
    logging_system_id,
    module_suffix,
    ...
  )
  arguments(
         "table", concatter,
      "function", logger,
      "function", date_checker,
        --"string", logging_system_id,
        "string", module_suffix
    )

  assert(is_function(logging_system_id) or is_string(logging_system_id))

  concatter.reset()

  local ts_before = os.time()
  logger(...)
  local ts_after = os.time()

  local actual = concatter.buf()

  -- Prepend system info to expected data
  local date = assert_is_string(actual[2])
  date_checker(date, ts_before, ts_after)

  if is_function(logging_system_id) then
    logging_system_id = assert_is_string(logging_system_id())
  end

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
    date_checker,
    logging_system,
    logging_system_id,
    ...
  )
  arguments(
      "table", concatter,
      "function", date_checker,
      "table", logging_system
      --"string", logging_system_id
    )
  for _, log_level in pairs(LOG_LEVEL) do
    local logger = ensure(
        "make_module_logger",
        logging_system:make_module_logger(
            "module_name", log_level, "MOD"
          )
      )

    check_logger(
        concatter, logger, date_checker,
        logging_system_id, "MOD",
        ...
      )
  end
end

--------------------------------------------------------------------------------

test:methods "get_config" -- TODO: no explicit tests
             "make_module_logger"

test "make_module_logger-empty" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          logging_system_id,
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL))
        )
    )

  check_make_module_logger(
      concatter, check_date_str, logging_system, logging_system_id
      -- Empty
    )
end)

test "make_module_logger-simple" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          logging_system_id,
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL))
        )
    )

  check_make_module_logger(
      concatter, check_date_str, logging_system, logging_system_id,
      42, "embedded\0zero", nil, true, nil
    )
end)

test "make_module_logger-id-callback-simple" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          function() return logging_system_id end,
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL))
        )
    )

  check_make_module_logger(
      concatter, check_date_str, logging_system, logging_system_id,
      42, "embedded\0zero", nil, true, nil
    )
end)

test "make_module_logger-id-callback-dynamic" (function()
  local concatter = make_test_concatter()

  local make_logging_system_id = function()
    local count = 0
    return function()
      count = count + 1
      return tostring(count)
    end
  end

  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          make_logging_system_id(),
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL))
        )
    )

  check_make_module_logger(
      concatter, check_date_str, logging_system, make_logging_system_id(),
      42, "embedded\0zero", nil, true, nil
    )
end)

test "make_module_logger-get_current_logsystem_date-simple" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "

  local date = "MYDATE"
  local date_checker = function(date_str, time_before, time_after)
    ensure_strequals("date match expected", date_str, date)
  end

  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          logging_system_id,
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL)),
          function() return date end
        )
    )

  check_make_module_logger(
      concatter, date_checker, logging_system, logging_system_id,
      42, "embedded\0zero", nil, true, nil
    )
end)

test "make_module_logger-table" (function()
  local concatter = make_test_concatter()
  local logging_system_id = "{logger_id} "
  local logging_system = ensure(
      "make logging system",
      make_logging_system(
          logging_system_id,
          concatter.cat,
          make_common_logging_config(tset(LOG_LEVEL))
        )
    )

  check_make_module_logger(
      concatter, check_date_str, logging_system, logging_system_id,
      nil, { [{ 42, nil, 24 }] = { a = 42 } }, nil
    )
end)

--------------------------------------------------------------------------------

test:factory "make_common_logging_config" (
    make_common_logging_config
  )

--------------------------------------------------------------------------------

local check_is_log_enabled = function(
    levels_config,
    modules_config,
    module_name,
    log_level,
    actually_enabled
  )
  optional_arguments(
      "table", levels_config,
      "table", modules_config
    )
  arguments(
       "string", module_name,
       "number", log_level,
      "boolean", actually_enabled
    )

  local concatter = make_test_concatter()

  local logging_system_id = "{logger_id} "
  local module_suffix = "MOD"

  local common_logging_config = make_common_logging_config(
      levels_config,
      modules_config
    )

  local logging_system = make_logging_system(
      logging_system_id,
      concatter.cat,
      common_logging_config
    )

  ensure_equals(
      "is_log_enabled",
      common_logging_config:is_log_enabled(module_name, log_level),
      actually_enabled
    )

  local logger = ensure(
      "make_module_logger",
      logging_system:make_module_logger(
          module_name, log_level, module_suffix
        )
    )

  if actually_enabled then
    check_logger(
        concatter, logger, check_date_str,
        logging_system_id, module_suffix,
        42, "embedded\0zero", nil, true, nil
      )
  else
    logger(42, "embedded\0zero", nil, true, nil)
    ensure_equals("logging is disabled", next(concatter.buf()), nil)
  end

  actually_enabled = not actually_enabled

  common_logging_config:set_log_enabled(module_name, log_level, actually_enabled)

  if actually_enabled then
    check_logger(
        concatter, logger, check_date_str,
        logging_system_id, module_suffix,
        42, "embedded\0zero", nil, true, nil
      )
  else
    logger(42, "embedded\0zero", nil, true, nil)
    ensure_equals("logging is disabled", next(concatter.buf()), nil)
  end
end

test:methods "set_log_enabled" -- TODO: no explicit tests found
             "is_log_enabled"

test "is_log_enabled-levels-default" (function()
  local module_name = "module_name"
  local levels_config = nil -- Default
  local modules_config = nil -- Default
  for _, log_level in pairs(LOG_LEVEL) do
    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        false -- actually disabled
      )
  end
end)

test "is_log_enabled-modules-default" (function()
  local module_name = "module_name"
  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  levels_config[LOG_LEVEL.ERROR] = false

  local modules_config = nil -- Default
  for _, log_level in pairs(LOG_LEVEL) do
    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        levels_config[log_level]
      )
  end
end)

test "is_log_enabled-modules-false" (function()
  local module_name = "module_name"
  local other_module_name = "other_module_name"
  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  local modules_config = { [module_name] = false }

  for _, log_level in pairs(LOG_LEVEL) do
    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        false
      )

    check_is_log_enabled( -- To ensure defaults are the same
        levels_config,
        modules_config,
        other_module_name,
        log_level,
        true
      )
  end
end)

test "is_log_enabled-modules-true" (function()
  local module_name = "module_name"
  local other_module_name = "other_module_name"
  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  local modules_config = { [module_name] = true }

  for _, log_level in pairs(LOG_LEVEL) do
    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        true
      )

    check_is_log_enabled( -- To ensure defaults are the same
        levels_config,
        modules_config,
        other_module_name,
        log_level,
        true
      )
  end
end)

test "is_log_enabled-modules-empty" (function()
  local module_name = "module_name"
  local other_module_name = "other_module_name"
  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  local modules_config = { [module_name] = { } }

  for _, log_level in pairs(LOG_LEVEL) do
    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        false
      )

    check_is_log_enabled( -- To ensure defaults are the same
        levels_config,
        modules_config,
        other_module_name,
        log_level,
        true
      )
  end
end)

test "is_log_enabled-modules-levels" (function()
  local module_config = { [LOG_LEVEL.LOG] = true, [LOG_LEVEL.SPAM] = false }
  local module_name = "module_name"
  local other_module_name = "other_module_name"
  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  local modules_config = { [module_name] = module_config }

  for _, log_level in pairs(LOG_LEVEL) do
    local actually_enabled = module_config[log_level]
    if actually_enabled == nil then
      actually_enabled = false
    end

    check_is_log_enabled(
        levels_config,
        modules_config,
        module_name,
        log_level,
        actually_enabled
      )

    check_is_log_enabled( -- To ensure defaults are the same
        levels_config,
        modules_config,
        other_module_name,
        log_level,
        true
      )
  end
end)

--------------------------------------------------------------------------------

test:tests_for "make_loggers"

--------------------------------------------------------------------------------

test "make_loggers-complex" (function()
  local concatter = make_test_concatter()

  local module_name = "module_name"
  local module_prefix = "MOD"
  local logging_system_id = "{logger_id} "

  local levels_config = tset(LOG_LEVEL) -- Enable all levels
  local modules_config = nil -- Default

  local common_logging_config = make_common_logging_config(
      levels_config,
      modules_config
    )

  local logging_system = make_logging_system(
      logging_system_id,
      concatter.cat,
      common_logging_config
    )

  local loggers_info =
  {
    { suffix = " ", level = LOG_LEVEL.LOG   };
    { suffix = "*", level = LOG_LEVEL.DEBUG };
    { suffix = "#", level = LOG_LEVEL.SPAM  };
    { suffix = "!", level = LOG_LEVEL.ERROR };
  }

  local loggers =
  {
    make_loggers(module_name, module_prefix, loggers_info, logging_system)
  }

  ensure_equals("number of loggers", #loggers, #loggers_info)

  -- Check default values
  for i = 1, #loggers_info do
    local logger_info = loggers_info[i]
    ensure_equals(
        "module logging on",
        common_logging_config:is_log_enabled(module_name, logger_info.level),
        true
      )
  end

  for i = 1, #loggers_info do
    local logger_info = loggers_info[i]
    local logger = loggers[i]

    local log_level = logger_info.level
    local module_suffix = module_prefix .. logger_info.suffix

    common_logging_config:set_log_enabled(module_name, log_level, true)

    check_logger(
        concatter, logger, check_date_str,
        logging_system_id, module_suffix,
        42, "embedded\0zero", nil, true, nil
      )

    common_logging_config:set_log_enabled(module_name, log_level, false)

    logger(42, "embedded\0zero", nil, true, nil)
    ensure_equals("logging is disabled", next(concatter.buf()), nil)
  end
end)

--------------------------------------------------------------------------------

assert(test:run())
