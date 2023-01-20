-- luacheck: globals import

-- TODO: This file contains functions from lua-aplicado/filesystem.lua
--       Replace them there with a standard deprecation shim

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local PATH_SEPARATOR = package.config:sub(1,1)
local IS_WINDOWS = (PATH_SEPARATOR == '\\')

--------------------------------------------------------------------------------

-- From penlight (modified)
--- given a path, return the directory part and a file part.
-- if there's no directory part, the first value will be empty
-- @param path A file path
local splitpath = function(path)
  local i = #path
  local ch = path:sub(i, i)
  while i > 0 and ch ~= "/" do
    i = i - 1
    ch = path:sub(i, i)
  end
  if i == 0 then
    return '', path
  else
    return path:sub(1, i - 1), path:sub(i + 1)
  end
end

local write_file = function(filename, new_data)
  arguments(
      "string", filename,
      "string", new_data
    )

  local file, err = io.open(filename, "w")
  if not file then
    return nil, err
  end

  file:write(new_data)
  file:close()

  return true
end

local read_file = function(filename)
  arguments(
      "string", filename
    )

  local file, err = io.open(filename, "r")
  if not file then
    return nil, err
  end

  local data = file:read("*a")
  file:close()

  return data
end


-- Inspired by path.join from MIT-licensed Penlight
-- https://github.com/stevedonovan/Penlight
--- Return the path resulting from combining the individual paths.
-- @param path1 A file path
-- @param path2 A file path
-- @param ... more file paths
local function join_path(path1, path2, ...)
  arguments(
      "string", path1,
      "string", path2
    )

  if select('#', ...) > 0 then
    return join_path(join_path(path1, path2), ...)
  end

  if
    path1:sub(#path1, #path1) ~= PATH_SEPARATOR and
    path2:sub(1, 1) ~= PATH_SEPARATOR
  then
      path1 = path1 .. PATH_SEPARATOR
  end

  return path1 .. path2
end

-- Inspired by path.normpath from MIT-licensed Penlight
-- https://github.com/stevedonovan/Penlight
--  A//B, A/./B and A/foo/../B all become A/B.
-- @param path a file path
local function normalize_path(path)
  arguments(
      "string", path
    )

  if IS_WINDOWS then
    if path:match '^\\\\' then -- UNC
        return '\\\\' .. normalize_path(path:sub(3))
    end
    path = path:gsub('/','\\')
  end

  local k
  -- /./ -> / ; // -> /
  local pattern = PATH_SEPARATOR .. "+%.?" .. PATH_SEPARATOR
  repeat
    path, k = path:gsub(pattern, PATH_SEPARATOR)
  until k == 0

  -- A/../ -> (empty)
  pattern = "[^" .. PATH_SEPARATOR .. "]+" .. PATH_SEPARATOR .. "%.%."
    .. PATH_SEPARATOR .. "?"
  repeat
      path, k = path:gsub(pattern,'')
  until k == 0

  if path == '' then path = '.' end
  return path
end

-------------------------------------------------------------------------------

return
{
  write_file = write_file;
  read_file = read_file;
  splitpath = splitpath;
  join_path = join_path;
  normalize_path = normalize_path;
}
