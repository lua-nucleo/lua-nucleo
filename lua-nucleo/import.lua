--------------------------------------------------------------------------------
--- Minimalistic Lua submodule system, with and without require
-- @module lua-nucleo.import
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local type, assert, loadfile, tostring, error, unpack, require, setmetatable,
      select
    = type, assert, loadfile, tostring, error, unpack, require, setmetatable,
      select

local create_import = function(init_with_require, code_root)
  local get_path
  local cache
  local import_in_progress_tag

  if init_with_require then
    cache = setmetatable(
        { },
        {
          __metatable = "name_cache";
          __index = function(t, k)
            local v = k:gsub("/", "."):gsub("\\", "."):gsub("%.lua$", "")
            t[k] = v
            return v
          end
        }
      )
  else
    import_in_progress_tag = function() end
    local base_path = code_root or ""
    local base_path_type = type(base_path)
    if base_path_type == "function" then
      get_path = base_path
    elseif base_path_type == "string" then
      get_path = function(filename)
        if not filename:find("^/") then
          return base_path .. filename
        else
          return filename
        end
      end
      cache = { }
    else
      error("import: bad base path type")
    end
  end

  return function(filename)
    local t
    local fn_type = type(filename)
    if fn_type == "table" then
      t = filename
    elseif fn_type == "string" then
      if init_with_require then
        t = assert(
            require(cache[filename]),
            "import: bad implementation",
            2
          )
        if t == true then
          -- This means that module did not return anything.
          error("import: bad implementation", 2)
        end
      else
        local full_path = get_path(filename)
        t = cache[filename]
        if t == nil then
          cache[filename] = import_in_progress_tag
          t = assert(
              assert(loadfile(full_path))(), "import: bad implementation", 2
            )
          cache[filename] = t
        elseif t == import_in_progress_tag then
          error(
              "import: cyclic dependency detected while loading: " .. filename,
              2
            )
        end
      end
    else
      error("import: bad filename type: " .. fn_type, 2)
    end

    return function(symbols)
      local result = { }
      local sym_type = type(symbols)

      if sym_type ~= "nil" then
        if sym_type == "table" then
          for i = 1, #symbols do
            local name = symbols[i]
            local v = t[name]
            if v == nil then
              error(
                  "import: key `" .. tostring(name) .. "' not found in `"
                  .. (fn_type == "string" and filename or "(table)") .. "'",
                  2
                )
            end
            result[i] = v
          end
        elseif sym_type == "string" then
          local v = t[symbols]
          if v == nil then
            error(
                "import: key `" .. symbols .. "' not found in `"
                .. (fn_type == "string" and filename or "(table)") .. "'",
                2
              )
          end
          result[1] = v
        else
          error("import: bad symbols type: " .. sym_type, 2)
        end

      end
      result[#result + 1] = t

      return unpack(result)
    end
  end
end

if declare then declare 'import' end

-- when module is loaded by require the first chunk parameter is the module name
local chunk_param = select(1, ...)
local init_with_require = chunk_param == "lua-nucleo.import"

import = create_import(init_with_require, chunk_param)
