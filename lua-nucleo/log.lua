--------------------------------------------------------------------------------
--- Logging system
-- @module lua-nucleo.log
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Split to separate files?
-- TODO: Logging levels should not be hardcoded
-- TODO: Table rendering must be configurable
--       (sometimes dump_object is needed instead of tstr)

-- TODO: Wish-list:
-- * allow per-log-level sinks
-- * collect similar lines ("last line repeats n times")
---  if timestamps are close enough.
-- * allows constant information prefixes (like PID)

--------------------------------------------------------------------------------

local type, setmetatable, tostring, select, assert, unpack
    = type, setmetatable, tostring, select, assert, unpack

local os_time, os_date
    = os.time, os.date

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

local is_string,
      is_function
      = import 'lua-nucleo/type.lua'
      {
        'is_string',
        'is_function'
      }

local assert_is_table,
      assert_is_string
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_string'
      }

local tflip,
      tstr_cat,
      tstr,
      tclone,
      tset,
      empty_table
      = import 'lua-nucleo/table.lua'
      {
        'tflip',
        'tstr_cat',
        'tstr',
        'tclone',
        'tset',
        'empty_table'
      }

local tidentityset
      = import 'lua-nucleo/table-utils.lua'
      {
        'tidentityset'
      }

local do_nothing,
      invariant
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing',
        'invariant'
      }

local create_escape_subst
      = import 'lua-nucleo/string.lua'
      {
        'create_escape_subst'
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

local LOG_FLUSH_MODE =
{
  ALWAYS = 1;
  EVERY_N_SECONDS = 2;
  NEVER = 3;
}

local FLUSH_SECONDS_DEFAULT = 1

local END_OF_LOG_MESSAGE = "\n"

--------------------------------------------------------------------------------

local make_common_logging_config
do
  local set_log_enabled = function(self, module_name, level, is_enabled)
    method_arguments(
        self,
        "string", module_name,
        "number", level,
        "boolean", is_enabled
      )

    if module_name then
      -- NOTE: Module config
      self.cache_[module_name][level] = is_enabled
    end
  end

  local is_log_enabled = function(self, module_name, level)
    method_arguments(
        self,
        "number", level,
        "string", module_name
      )

    return self.cache_[module_name][level]
  end

  local is_log_enabled_raw = function(
      modules_config,
      levels_config,
      module_name,
      level
    )
    arguments(
        "table", levels_config,
        "table", modules_config,
        "string", module_name,
        "number", level
      )

    if levels_config[level] then -- Levels are disabled by default
      local module_config = modules_config[module_name]
      if module_config == true or module_config == nil then -- Modules are enabled by default
        return true
      elseif module_config ~= false then
        -- Per-module levels are disabled by default as well
        return not not assert_is_table(module_config)[level]
      end
    end

    return false
  end

  local make_config_cache = function(levels_config, modules_config)
    return setmetatable(
        { },
        {
          __index = function(modules, module_name)
            local level_info = setmetatable(
                { },
                {
                  __index = function(levels, level)
                    local is_enabled = is_log_enabled_raw(
                        modules_config,
                        levels_config,
                        module_name,
                        level
                      )
                    levels[level] = is_enabled
                    return is_enabled
                  end;
                }
              )
            modules[module_name] = level_info
            return level_info
          end;
        }
      )
  end

  make_common_logging_config = function(
      levels_config,
      modules_config,
      flush_type,
      flush_time,
      bufsize
    )
    levels_config = levels_config or empty_table
    modules_config = modules_config or empty_table
    flush_type = flush_type or LOG_FLUSH_MODE.EVERY_N_SECONDS
    flush_time = flush_time or FLUSH_SECONDS_DEFAULT
    -- Assuming 2048 to be minimal BUFSIZ value that one can encounter
    -- in the wild these days
    bufsize = bufsize or 2048 * 0.75
    arguments(
        "table", levels_config,
        "table", modules_config,
        "number", flush_type,
        "number", flush_time,
        "number", bufsize
      )
    return
    {
      set_log_enabled = set_log_enabled;
      is_log_enabled = is_log_enabled; -- Required method
      last_flush_time = 0;
      flush_type = flush_type;
      flush_time = flush_time;
      bufsize = bufsize;
      --
      cache_ = make_config_cache(levels_config, modules_config);
    }
  end
end

--------------------------------------------------------------------------------

local make_logging_system
do
  local logger_escape
  do
    -- Emulating Lua "%q" escape style, as tstr_cat() would use it
    -- We do not dare to log any binary characters
    -- Note that there is no sense to keep \128-\255 bytes unescaped,
    -- since we already escape bytes in %c range,
    -- and that ruins UTF-8 anyway.
    local escape_subst = create_escape_subst("\\%03d")

    logger_escape = function(s)
      return tostring(s):gsub("[%c%z\128-\255]", escape_subst)
    end
  end

  -- private method
  local wrap_sink = function(self, sink)
    method_arguments(
        self,
        "function", sink
      )

    local function wrapped_sink(s)
      -- Assuming argument to be always a string, as per sink() contract.
      self.bytes_to_next_flush_ = self.bytes_to_next_flush_ - #s

      sink(s)

      return wrapped_sink
    end

    return wrapped_sink
  end

  local make_module_logger
  do
    local function impl(self, timestamp, nargs, v, ...)
      -- Sink the entire log message first
      if nargs > 0 then
        if type(v) ~= "table" then
          v = logger_escape(v)
        else
          -- Assuming this does necessary escapes.
          -- Note that under vanilla Lua 5.1 it does not escape
          -- all necessary control characters (that's %q implementation
          -- fault).
          v = tstr(v)
        end

        self.sink_(v)
        if nargs > 1 then
          self.sink_(" ")
          return impl(self, timestamp, nargs - 1, ...)
        end
      end

      -- Log a newline.
      self.sink_(END_OF_LOG_MESSAGE)

      -- Now, let's see if we need to flush.
      -- Note that we want to do this only at EOLM,
      -- to ensure that if several processes are writing
      -- to the same log file, all log lines are still intact.

      local config = self:get_config()

      -- Note that we use >, not >= when comparing timestamps,
      -- since time may have large granularity (seconds), and thus
      -- this function may be called several times per
      -- self.timestamp_ value.
      local need_flush = (config.flush_type == LOG_FLUSH_MODE.ALWAYS)
        or (
            config.flush_type == LOG_FLUSH_MODE.EVERY_N_SECONDS
              and (
                  timestamp > self.next_flush_timestamp_ or
                  self.bytes_to_next_flush_ <= 0
                )
          )

      if need_flush then
        self.flush_()
        self.next_flush_timestamp_ = timestamp + config.flush_time
        -- TODO: Rename config.bufsize as per review.
        self.bytes_to_next_flush_ = config.bufsize
      end

      -- TODO: Make sure this is absolutely needed.
      --       Now that we have advanced flush semantics,
      --       using returned value directly may lead to log synch problems.
      return self.sink_
    end

    make_module_logger = function(
        self, -- logging_system object
        module_name,
        level,
        suffix
      )
      method_arguments(
          self,
          "string", module_name,
          "number", level,
          "string", suffix
        )

      return function(...)
        if self:get_config():is_log_enabled(module_name, level) then
          local timestamp = self.get_time_() -- TODO: Hack

          self.sink_ "[" (
              self.date_fn_(timestamp)
            ) "] " (self.logger_id_()) "[" (suffix) "] "

          return impl(
              self,
              timestamp,
              select("#", ...), ...
            )
        end
      end
    end
  end

  local get_config = function(self)
    method_arguments(self)
    return self.config_
  end

  -- Sink must behave like io.write(). Newlines are explicit!
  -- However, sink may safely assume that end-of-atomic-log-message
  -- is always signalled by a single newline character.
  --
  -- Sink also must behave like cat(), that is, return itself.
  --
  -- Sink must not flush the logging stream.
  --
  make_logging_system = function(
      logger_id,
      sink,
      logging_config,
      date_fn,
      flush,
      get_time
    )
    if is_string(logger_id) then
      logger_id = invariant(logger_id)
    end

    date_fn = date_fn or get_current_logsystem_date
    flush = flush or do_nothing
    get_time = get_time or os_time

    arguments(
        "function", logger_id,
        "function", sink,
        "table", logging_config,
        "function", date_fn,
        "function", flush,
        "function", get_time
      )

    local self =
    {
      get_config = get_config;
      make_module_logger = make_module_logger;
      --
      logger_id_ = logger_id;
      sink_ = nil; -- set below
      date_fn_ = date_fn;
      config_ = logging_config;
      flush_ = flush;
      get_time_ = get_time;
      -- Shared state to ensure consistent flushing --
      bytes_to_next_flush_ = 0;
      next_flush_timestamp_ = 0;
    }

    self.sink_ = wrap_sink(self, sink)

    return self
  end
end

--------------------------------------------------------------------------------

local wrap_file_sink = function(file)
  -- TODO: assert_is_object(file)
  local function sink(v)
    -- Accepts only strings, by contract, no type checks for speed
    file:write(v)
    -- Note that fsync is now done by the logging system
    return sink
  end

  return sink
end

--------------------------------------------------------------------------------

local get_current_logsystem_date_microsecond = function(time)
  time = time or socket.gettime()
  return format_logsystem_date(time) .. ("%.6f")
    :format(time % 1)
    :sub(2, -1)
end

local STDOUT_LOGGERS_INFO = -- Order is important!
{
  { suffix = " ", level = LOG_LEVEL.LOG   };
  { suffix = "*", level = LOG_LEVEL.DEBUG };
  { suffix = "#", level = LOG_LEVEL.SPAM  };
  { suffix = "!", level = LOG_LEVEL.ERROR };
}

local create_stdout_logging_system,
      is_stdout_logging_system_initialized,
      get_stdout_logging_system
do
  local STDOUT_LOG_MODULE_CONFIG = { } -- everything is enabled by default.  
  local STDOUT_LOG_LEVEL_CONFIG =
  {
    [LOG_LEVEL.ERROR] = true;
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
  }

  local logging_system_id = "{TTTTT} "
  
  local get_logging_system_id = function()
    return logging_system_id
  end

  local stdout_logging_system = nil

  create_stdout_logging_system = function()
    assert(
        stdout_logging_system == nil,
        "double create_stdout_logging_system call"
      )

    stdout_logging_system = make_logging_system(
        get_logging_system_id,
        wrap_file_sink(io.stdout),
        make_common_logging_config(
            STDOUT_LOG_LEVEL_CONFIG,
            STDOUT_LOG_MODULE_CONFIG
          ),
        get_current_logsystem_date_microsecond
      )
  end

  is_stdout_logging_system_initialized = function()
    return not not stdout_logging_system
  end

  get_stdout_logging_system = function()
    return assert(stdout_logging_system, "stdout_logging_system not created")
  end
end

--------------------------------------------------------------------------------

local make_loggers_old, make_loggers
do
  local function impl(logger, module_name, module_prefix, info, ...)
    if info then
      return
          logger:make_module_logger(
              module_name,
              assert(info.level),
              module_prefix .. assert_is_string(info.suffix)
            )
        , impl(logger, module_name, module_prefix, ...)
    end
    return nil
  end

  make_loggers_old = function(
      module_name,
      module_prefix,
      loggers_info,
      logging_system
    )
    arguments(
        "string", module_name,
        "string", module_prefix,
        "table",  loggers_info,
        "table",  logging_system
      )

    return impl(
        logging_system,
        module_name,
        module_prefix,
        unpack(loggers_info)
      )
  end

  make_loggers = function (
      module_name,
      module_prefix,
      loggers_info,
      logging_system
    )

    if loggers_info == nil then
      arguments(
        "string", module_name,
        "string", module_prefix
      )

      if not is_stdout_logging_system_initialized() then

      end

      return impl(
          get_stdout_logging_system(),
          module_name,
          module_prefix,
          STDOUT_LOGGERS_INFO
        )
    else
      arguments(
        "string", module_name,
        "string", module_prefix,
        "table",  loggers_info,
        "table",  logging_system
      )

      return impl(
          logging_system,
          module_name,
          module_prefix,
          unpack(loggers_info)
        )
    end    
  end
end

--------------------------------------------------------------------------------

return
{
  LOG_LEVEL = LOG_LEVEL;
  END_OF_LOG_MESSAGE = END_OF_LOG_MESSAGE;
  LOG_FLUSH_MODE = LOG_FLUSH_MODE;
  FLUSH_SECONDS_DEFAULT = FLUSH_SECONDS_DEFAULT;
  --
  format_logsystem_date = format_logsystem_date;
  get_current_logsystem_date = get_current_logsystem_date;
  --
  make_common_logging_config = make_common_logging_config;
  make_logging_system = make_logging_system;
  wrap_file_sink = wrap_file_sink;
  --
  make_loggers = make_loggers;
}
