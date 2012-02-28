--------------------------------------------------------------------------------
-- rockspec/generate.lua: lua-nucleo dumb rockspec generator
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

pcall(require, 'luarocks.require') -- Ignoring errors

local lfs = require 'lfs'

-- From lua-aplicado.
local function find_all_files(path, regexp, dest, mode)
  dest = dest or {}
  mode = mode or false

  assert(mode ~= "directory")

  for filename in lfs.dir(path) do
    if filename ~= "." and filename ~= ".." then
      local filepath = path .. "/" .. filename
      local attr = lfs.attributes(filepath)
      if attr.mode == "directory" then
        find_all_files(filepath, regexp, dest)
      elseif not mode or attr.mode == mode then
        if filename:find(regexp) then
          dest[#dest + 1] = filepath
          -- print("found", filepath)
        end
      end
    end
  end

  return dest
end

local files = find_all_files("lua-nucleo", "^.*%.lua$")
table.sort(files)

io.stdout:write([[
package = "lua-nucleo"
version = "]] .. (select(1, ...) or "scm-1") .. [["
source = {
   url = "git://github.com/lua-nucleo/lua-nucleo.git",
   branch = "master"
}
description = {
   summary = "A random collection of core and utility level Lua libraries",
   homepage = "http://github.com/lua-nucleo/lua-nucleo",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "none",
   install = {
      lua = {
]])

for i = 1, #files do
  local name = files[i]
  if name ~= "lua-nucleo/import.lua" then -- Hack
    io.stdout:write([[
         []] .. (
            ("%q"):format(
                name:gsub("/", "."):gsub("\\", "."):gsub("%.lua$", "")
              )
          ) .. [[] = ]] .. (("%q"):format(name)) .. [[;
]])
  end
end

io.stdout:write([[
      }
   }
}
]])
io.stdout:flush()
