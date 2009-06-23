-- import.lua -- minimalistic Lua submodule system
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

if exports then exports 'import' end

local type, assert, loadfile, ipairs, tostring, error, unpack 
    = type, assert, loadfile, ipairs, tostring, error, unpack 
    
local getmetatable, setmetatable
    = getmetatable, setmetatable

do
  local cache = {}

  local call = function(t, symbols)
    local result = {}
    local sym_type = type(symbols)

    if sym_type == "table" then
      for i, name in ipairs(symbols) do
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
    elseif sym_type ~= "nil" then
      error("import: bad symbol type: `"..sym_type.."'", 2)
    end
    result[#result + 1] = t

    return unpack(result)
  end

  local mt_tag = { "import" } -- Should have unique tag

  local mt = 
  {
    __call = call;
    __metatable = mt_tag;
  }

  import = function(filename)
    local t
    local fn_type = type(filename)
    
    local need_mt = false
    
    if fn_type == "table" then
      t = filename
      need_mt = true
    elseif fn_type == "string" then
      t = cache[filename]
      if t == nil then
        -- TODO: Support multiple return values 
        t = assert(loadfile(filename))()
        if t == nil then
          error("import: bad implementation", 2)
        end

        cache[filename] = t
        
        need_mt = true
      end
    else
      error("import: bad filename type: `"..fn_type.."`", 2)
    end

    if need_mt and type(t) == 'table' then
      -- NOTE: We explicitly chose not to deal with tables with metatables.
      --       What to do if metatable has __metatable field set for example?
      local old_mt = getmetatable(t)
      if old_mt ~= mt_tag then
        if old_mt ~= nil then
          error("import: can't have metatable on object", 2)
        end
        setmetatable(t, mt)
      end
    end
    -- NOTE: All other types (including userdata) are to be passed as is.

    return t
  end
end
