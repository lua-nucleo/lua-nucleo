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
      tclone,
      tset,
      empty_table
      = import 'lua-nucleo/table.lua'
      {
        'tflip',
        'tstr_cat',
        'tclone',
        'tset',
        'empty_table'
      }

local tidentityset
      = import 'lua-nucleo/table-utils.lua'
      {
        'tidentityset'
      }

local do_nothing
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing'
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
      flush_time
    )
    levels_config = levels_config or empty_table
    modules_config = modules_config or empty_table
    flush_type = flush_type or LOG_FLUSH_MODE.EVERY_N_SECONDS
    flush_time = flush_time or FLUSH_SECONDS_DEFAULT
    arguments(
        "table", levels_config,
        "table", modules_config,
        "number", flush_type,
        "number", flush_time
      )
    return
    {
      set_log_enabled = set_log_enabled;
      is_log_enabled = is_log_enabled; -- Required method
      last_flush_time = 0;
      flush_type = flush_type;
      flush_time = flush_time;
      --
      cache_ = make_config_cache(levels_config, modules_config);
    }
  end
end

--------------------------------------------------------------------------------

local make_logging_system
do
  -- Emulating Lua "%q" escape style, as tstr_cat() would use it
  local escape_subst = create_escape_subst("\\%03d")

  -- Private function
  local make_logger
  do
    local function impl(sink, n, v, ...)
      if n > 0 then
        if type(v) ~= "table" then
          -- We do not dare to log any binary characters
          -- Note that there is no sense to keep \128-\255 bytes unescaped,
          -- since we already escape bytes in %c range, and that ruins UTF-8 anyway.
          sink(tostring(v):gsub("[%c%z\128-\255]", escape_subst))
        else
          tstr_cat(sink, v) -- Assuming this does not emit "\n"
        end

        if n > 1 then
          sink(" ")
          return impl(sink, n - 1, ...)
        end
      end

      return sink(END_OF_LOG_MESSAGE)
    end

    make_logger = function( -- TODO: rename, is not factory
        logging_config,
        module_name,
        level,
        sink,
        flush,
        date_fn,
        get_time,
        logger_id,
        suffix
      )
      arguments(
          "table", logging_config,
          "string", module_name,
          "number", level,
          "function", sink,
          "function", flush,
          "function", date_fn,
          "function", get_time,
          --"string", logger_id, -- TODO: Need metatype, may be function or string
          "string", suffix
        )

      if is_function(logger_id) then
        return function(...)
          if logging_config:is_log_enabled(module_name, level) then
            local time = get_time()
            sink "[" (date_fn(time)) "] " (logger_id())
                "[" (suffix) "] "
            if
              logging_config.flush_type == LOG_FLUSH_MODE.EVERY_N_SECONDS
                and time > logging_config.last_flush_time + logging_config.flush_time
            then
              flush()
              logging_config.last_flush_time = time
            end
            -- NOTE: Using explicit size since we have to support holes in the vararg.
            return impl(sink, select("#", ...), ...)
          end
        end
      else
        assert_is_string(logger_id)
        return function(...)
          if logging_config:is_log_enabled(module_name, level) then
            local time = get_time()
            sink "[" (date_fn(time)) "] " (logger_id)
                "[" (suffix) "] "
            if
              logging_config.flush_type == LOG_FLUSH_MODE.EVERY_N_SECONDS
                and time > logging_config.last_flush_time + logging_config.flush_time
            then
              flush()
              logging_config.last_flush_time = time
            end
            -- NOTE: Using explicit size since we have to support holes in the vararg.
            return impl(sink, select("#", ...), ...)
          end
        end
      end
    end
  end

  local make_module_logger = function(self, module_name, level, suffix)
    method_arguments(
        self,
        "string", module_name,
        "number", level,
        "string", suffix
      )

    return make_logger(
        self.config_,
        module_name,
        level,
        self.sink_,
        self.flush_,
        self.date_fn_,
        self.get_time_,
        self.logger_id_,
        suffix
      )
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
  make_logging_system = function(
      logger_id,
      sink,
      logging_config,
      date_fn,
      flush,
      get_time
    )
    date_fn = date_fn or get_current_logsystem_date
    flush = flush or function() end
    get_time = get_time or os_time
    assert(is_string(logger_id) or is_function(logger_id))
    arguments(
        -- "string", logger_id, -- TODO: Need metatype may be function or string
        "function", sink,
        "table", logging_config,
        "function", date_fn,
        "function", flush,
        "function", get_time
      )

    return
    {
      get_config = get_config;
      make_module_logger = make_module_logger;
      --
      logger_id_ = logger_id;
      sink_ = sink;
      date_fn_ = date_fn;
      config_ = logging_config;
      flush_ = flush;
      get_time_ = get_time;
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

local make_loggers
do
  local function impl(logger, module_name, module_prefix, info, ...)
    if info then
      return
          logger:make_module_logger(
              module_name,
              assert(info.level),
              module_prefix .. assert(info.suffix)
            )
        , impl(logger, module_name, module_prefix, ...)
    end
    return nil
  end

  make_loggers = function(
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
