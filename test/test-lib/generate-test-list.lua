-- generate-test-list.lua: generates list of test files to be run
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local lfs = require 'lfs'

local function find_all_files(path, regexp, dest)
  dest = dest or {}
  for filename in lfs.dir(path) do
    if filename ~= "." and filename ~= ".." then
      local filepath = path .. "/" .. filename
      local attr = lfs.attributes(filepath)
      if attr.mode == "directory" then
        find_all_files(filepath, regexp, dest)
      elseif filename:find(regexp) then
        dest[#dest + 1] = filename
        print(dest[#dest])
      end
    end
  end
  return dest
end

local cases = find_all_files("test/cases", ".lua")

local file, err = io.open("test/test-list.lua", "w")
file:write("-- all-tests.lua: the list of all tests in the library\n"
        .. "-- This file is generetad by lua-nucleo library\n"
        .. "-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)\n\n"
        .. "return\n{\n")
for i = 1, #cases do
  file:write("  '" .. cases[i]:match("([%w%-_]+).lua") .. "';\n")
end
file:write("}\n")

-- TODO: find that tests match library
-- local libraries = find_all_files("./lua-nucleo", ".lua")

file:close()
