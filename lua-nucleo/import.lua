--------------------------------------------------------------------------------
--- Minimalistic Lua submodule system
-- @module lua-nucleo.import
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

if exports then exports 'import' end

local type, assert, loadfile, tostring, error, unpack
    = type, assert, loadfile, tostring, error, unpack

local get_path
do
  local base_path = (...) or ""

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
  else
    error("import: bad base path type")
  end
end

do
  local import_cache = { }

  local import_in_progress_tag = function() end

  import = function(filename)
    local t
    local fn_type = type(filename)
    if fn_type == "table" then
      t = filename
    elseif fn_type == "string" then
      local full_path = get_path(filename)

      t = import_cache[filename]
      if t == nil then
        import_cache[filename] = import_in_progress_tag
        t = assert(assert(loadfile(full_path))(), "import: bad implementation", 2)
        import_cache[filename] = t
      elseif t == import_in_progress_tag then
        error("import: cyclic dependency detected while loading: "..filename, 2)
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
              error(
                  "import: key `"..tostring(name).."' not found in `"
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
                "import: key `"..symbols.."' not found in `"
             .. (fn_type == "string" and filename or "(table)") .. "'",
                2
              )
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
