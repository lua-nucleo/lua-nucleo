--------------------------------------------------------------------------------
--- Common DSL schema loader
-- @module lua-nucleo.dsl.common_load_schema
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------
-- Sandbox warning: alias all globals!
--------------------------------------------------------------------------------

local debug_traceback, debug_getinfo = debug.traceback, debug.getinfo

local assert, error, pairs, rawset, setfenv
    = assert, error, pairs, rawset, setfenv

local setmetatable, tostring, xpcall, select
    = setmetatable, tostring, xpcall, select

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local is_table,
      is_function,
      is_string
      = import 'lua-nucleo/type.lua'
      {
        'is_table',
        'is_function',
        'is_string'
      }

local assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table'
      }

local tset,
      torderedset,
      torderedset_insert,
      torderedset_remove,
      tivalues,
      twithdefaults
      = import 'lua-nucleo/table-utils.lua'
      {
        'tset',
        'torderedset',
        'torderedset_insert',
        'torderedset_remove',
        'tivalues',
        'twithdefaults'
      }

local make_dsl_loader
      = import 'lua-nucleo/dsl/dsl_loader.lua'
      {
        'make_dsl_loader'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

--------------------------------------------------------------------------------

-- NOTE: Lazy! Do not create so many closures!
local common_load_schema -- TODO: Generalize more. Apigen uses similar code.
-- #tmp3001
do
  local env_mt_tag = unique_object()

  common_load_schema = function(
      chunks,
      extra_env,
      allowed_namespaces,
      need_file_line
    )
    if is_function(chunks) then
      chunks = { chunks }
    end

    extra_env = extra_env or { }
    arguments(
        "table", chunks,
        "table", extra_env
      )
    optional_arguments(
        "table", allowed_namespaces,
        "boolean", need_file_line -- Hack. Not generic enough
      )
    if allowed_namespaces then
      allowed_namespaces = tset(allowed_namespaces)
    end

    local positions = torderedset({ })
    local unhandled_positions = { }
    local soup = { }

    local make_common_loader = function(namespace)
      arguments("string", namespace)

      local name_filter = function(tag, name, ...)
        assert(select("#", ...) == 0, "extra arguments are not supported")

        local data

        if is_table(name) then -- data-only-call
          -- Allowing data.name to be missing.
          data = name
        elseif is_function(name) then -- handler-only-call
          -- Allowing data.name to be missing.
          data =
          {
            handler = name;
          }
        else -- normal named call
          data =
          {
            name = name;
          }
        end

        data.tag = tag
        data.namespace = namespace;
        data.id = namespace .. ":" .. tag

        -- Calls to debug.getinfo() are slow,
        -- so we're not doing them by default.
        if need_file_line then
          -- TODO: Hack. Implement a general solution as described in #is3008

          local level, info
          do
            local DEFAULT_LEVEL = 3 -- Hack. Depends on implementation.
            local cur_level = 1

            local ok, env = pcall(getfenv, cur_level)
            while ok do
              local is_our_mt = (getmetatable(env) == env_mt_tag)
              if is_our_mt then
                info = debug_getinfo(cur_level, "Sl")
                if info.what ~= 'C' and info.what ~= 'tail' then
                  level = cur_level
                else
                  -- TODO: Figure out why this magic is needed.
                  level = cur_level - 1
                  info = nil
                end
                break
              end

              cur_level = cur_level + 1
              ok, env = pcall(getfenv, cur_level)
            end

            level = level or DEFAULT_LEVEL
            info = info or debug_getinfo(level, "Sl")
          end

          data.source_ = info.source
          data.file_ = info.short_src
          data.line_ = info.currentline
        end

        torderedset_insert(positions, data)
        unhandled_positions[data] = positions[data]

        return data
      end

      local data_filter = function(name_data, value_data)
        assert_is_table(name_data)

        -- A special case for handler-only named tags
        if is_function(value_data) then
          value_data =
          {
            handler = value_data;
          }
        end

        if is_string(value_data) then
          value_data =
          {
            [1] = value_data;
          }
        end

        -- Letting user to override any default values (including name and tag)
        local data = twithdefaults(value_data, name_data)

        local position = assert(positions[name_data])
        assert(soup[position] == nil)
        soup[position] = data

        -- Can't remove from set, need id to be taken
        unhandled_positions[name_data] = nil

        return data
      end

      return make_dsl_loader(name_filter, data_filter)
    end

    local loaders = { }

    local environment = setmetatable(
        { },
        {
          __metatable = env_mt_tag;

          __index = function(t, namespace)
            -- Can't put it as setmetatable first argument -- 
            -- we heavily change that table afterwards.
            local v = extra_env[namespace]
            if v ~= nil then
              return v
            end

            -- NOTE: optimizable. Employ metatables.
            if allowed_namespaces and not allowed_namespaces[namespace] then
              error(
                  "attempted to read from global `"
               .. tostring(namespace) .. "'",
                  2
                )
            end

            local loader = make_common_loader(namespace)
            loaders[namespace] = loader

            local v = loader:get_interface()
            rawset(t, namespace, v)
            return v
          end;

          __newindex = function(t, k, v)
            error("attempted to write to global `" .. tostring(k) .. "'", 2)
          end;
        }
      )

    for i = 1, #chunks do
      local chunk = chunks[i]

      -- NOTE: Chunk environment is not restored
      setfenv(
          chunk,
          environment
        )

      assert(
          xpcall(
              chunk,
              function(err)
                return debug_traceback(err, 2)
              end
            )
        )
    end

    -- For no-name top-level tags
    for data, position in pairs(unhandled_positions) do
      assert(soup[position] == nil)
      soup[position] = data
    end

    assert(#soup > 0, "no data in schema")

    for _, loader in pairs(loaders) do
      soup = loader:finalize_data(soup)
    end

    -- NOTE: Optimizeable. Try to get the list of top-level nodes from dsl_loader.
    soup = torderedset(soup)

    local function unsoup(soup, item)
      for k, v in pairs(item) do
        if is_table(k) then
          torderedset_remove(soup, k)
          unsoup(soup, k)
        end
        if is_table(v) then
          torderedset_remove(soup, v)
          unsoup(soup, v)
        end
      end

      return soup
    end

    local values = tivalues(soup) -- NOTE: Hack. Workaround for torderedset changing value order

    local n_soup = #values
    for i = 1, n_soup do
      unsoup(soup, values[i])
    end

    local schema = tivalues(soup) -- Get rid of the set part

    return schema
  end
end

--------------------------------------------------------------------------------

return
{
  common_load_schema = common_load_schema;
}
