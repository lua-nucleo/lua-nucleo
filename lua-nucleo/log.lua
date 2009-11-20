-- log.lua: logging system
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Split to separate files?
-- TODO: Logging levels should not be hardcoded
-- TODO: Table rendering must be configurable
--       (sometimes dump_object is needed instead of tstr)

-- TODO: Wish-list:
-- * allow per-log-level sinks
-- * collect similar lines ("last line repeats n times") if timestamps are close enough.
-- * allows constant information prefixes (like PID)

--------------------------------------------------------------------------------

local type = type
local os_time, os_date = os.time, os.date

--------------------------------------------------------------------------------

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local tflip,
      tstr_cat
      = import 'lua-nucleo/table.lua'
      {
        'tflip',
        'tstr_cat'
      }

local do_nothing
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing'
      }

--------------------------------------------------------------------------------

-- TODO: Move to a separate file
local format_logsystem_date = function(time)
  return os_date("%Y-%m-%d %H:%M:%S", time)
end

local get_current_logsystem_date
do
  local last_time = os_time()
  local last_time_str = format_logsystem_date(last_time)

  get_current_logsystem_date = function()
    local cur_time = os_time()
    if cur_time ~= last_time then -- Assuming integer seconds
      last_time = cur_time
      last_time_str = format_logsystem_date(cur_time)
    end
    return last_time_str
  end
end

--------------------------------------------------------------------------------

-- TODO: Wrap in tenum
local LOG_LEVEL =
{
  ERROR = 1;
  LOG   = 2;
  DEBUG = 3;
  SPAM  = 4;
}

local END_OF_LOG_MESSAGE = "\n"

--------------------------------------------------------------------------------

local make_logging_system
do
  -- Private function
  local make_logger
  do
    local function impl(sink, n, v, ...)
      local v_type = type(v)
      if v_type ~= "table" then
        sink(tostring(v))
      else
        tstr_cat(sink, v) -- Assuming this does not emit "\n"
      end

      if n > 1 then
        sink(" ")

        if n > 0 then
          return impl(sink, n - 1, ...)
        end
      end

      return sink(END_OF_LOG_MESSAGE)
    end

    make_logger = function(sink, logger_id, suffix)
      return function(...)
        -- NOTE: Using explicit size since we have to support holes in the vararg.
        sink "[" (get_current_logsystem_date()) "] " (logger_id)
             "[" (suffix) "] "

        return impl(sink, select("#", ...), ...)
      end
    end
  end

  local is_log_enabled = function(self, module_name, level)
    method_arguments(
        self,
        "string", module_name,
        "number", level
      )

    if self.levels_config_[level] then -- Levels are disabled by default
      local module_config = self.modules_config_[module_name]
      if module_config == true or module_config == nil then -- Modules are enabled by default
        return true
      elseif module_config ~= false then
        return assert_is_table(module_config)[level] -- Per-module levels are disabled by default as well
      end
    end

    return false
  end

  local make_module_logger = function(self, module_name, level, suffix)
    method_arguments(
        self,
        "string", module_name,
        "number", level,
        "string", suffix
      )

    return self:is_log_enabled(module_name, level)
       and make_logger(self.sink_, self.logger_id, suffix)
        or do_nothing
  end

  -- Sink must behave like io.write(). Newlines are explicit!
  -- However, sink may safely assume that end-of-atomic-log-message
  -- is always signalled by a single newline character.
  --
  -- Sink also must behave like cat(), i.e. return itself.
  --
  -- Intentionally not supporting level and module configuration changes
  -- to enhance speed.
  make_logging_system = function(logger_id, sink, levels_config, modules_config)
    levels_config = levels_config or {}
    modules_config = modules_config or {}

    arguments(
        "string", logger_id,
        "function", sink,
        "table", levels_config,
        "table", modules_config
      )

    return
    {
      is_log_enabled = is_log_enabled;
      make_module_logger = make_module_logger;
      --
      logger_id_ = logger_id;
      sink_ = sink;
      levels_config_ = levels_config;
      modules_config_ = modules_config;
    }
  end
end

--------------------------------------------------------------------------------

local wrap_file_sink = function(file)
  -- TODO: assert_is_object(file)
  local function sink(v)
    file:write(v)
    if v == END_OF_LOG_MESSAGE then
      file:flush() -- TODO: ?! Slow.
    end
    return sink
  end

  return sink
end

--------------------------------------------------------------------------------

-- TODO: Generalize to make_singleton?
local create_common_logging_system, get_common_logging_system
do
  local common_logging_system = nil

  create_common_logging_system = function(...)
    -- Override intentionally disabled to ensure consistency.
    -- If needed, implement in a separate function.
    assert(
        common_logging_system == nil,
        "double create_common_logging_system call"
      )

    common_logging_system = make_logging_system(...)
  end

  get_common_logging_system = function()
    return assert(common_logging_system, "common_logging_system not created")
  end
end

--------------------------------------------------------------------------------

local make_loggers
do
  local COMMON_LOGGERS_INFO =
  {
    { suffix = " ", level = LOG_LEVEL.LOG   };
    { suffix = "*", level = LOG_LEVEL.DEBUG };
    { suffix = "#", level = LOG_LEVEL.SPAM  };
    { suffix = "!", level = LOG_LEVEL.ERROR };
  }

  local function impl(logger, module_name, module_prefix, info, ...)
    if info then
      return
          logger:make_module_logger(
              module_name,
              assert(info.level),
              module_prefix..assert(info.suffix)
            )
        , impl(logger, module_name, module_prefix, ...)
    end
    return nil
  end

  make_loggers = function(module_name, module_prefix, info, logger)
    info = info or COMMON_LOGGERS_INFO
    logger = logger or get_common_logging_system()

    arguments(
        "string", module_name,
        "string", module_prefix,
        "table", info,
        "table", logger
      )

    return impl(logger, module_name, module_prefix, unpack(info))
  end
end

--------------------------------------------------------------------------------

return
{
  LOG_LEVEL = LOG_LEVEL;
  END_OF_LOG_MESSAGE = END_OF_LOG_MESSAGE;
  --
  format_logsystem_date = format_logsystem_date;
  get_current_logsystem_date = get_current_logsystem_date;
  make_logging_system = make_logging_system;
  wrap_file_sink = wrap_file_sink;
  create_common_logging_system = create_common_logging_system;
  get_common_logging_system = get_common_logging_system;
  --
  make_loggers = make_loggers;
}
