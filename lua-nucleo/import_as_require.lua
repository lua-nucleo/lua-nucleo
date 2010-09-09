-- import_as_require.lua: minimalistic Lua submodule system using require
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local type, assert, loadfile, tostring, error, unpack, require, setmetatable
    = type, assert, loadfile, tostring, error, unpack, require, setmetatable

-- TODO: Try to generalize copy-paste from import.lua
local import
do
  local name_cache = setmetatable(
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

  import = function(filename)
    local t
    local fn_type = type(filename)
    if fn_type == "table" then
      t = filename
    elseif fn_type == "string" then
      -- TODO: Get path separator from somewhere
      t = assert(
          require(name_cache[filename]),
          "import: bad implementation",
          2
        )

      if t == true then
        -- This means that module did not return anything.
        error("import: bad implementation", 2)
      end
    else
      error("import: bad filename type: "..fn_type, 2)
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
              error("import: key `"..tostring(name).."' not found", 2)
            end
            result[i] = v
          end
        elseif sym_type == "string" then
          local v = t[symbols]
          if v == nil then
            error("import: key `"..symbols.."' not found", 2)
          end
          result[1] = v
        else
          error("import: bad symbols type: "..sym_type, 2)
        end

      end
      result[#result + 1] = t

      return unpack(result)
    end
  end
end

return
{
  import = import;
}
