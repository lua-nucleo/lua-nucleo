-- generate-test-list.lua: generates list of test files to be run
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local print, string, io, os = print, string, io, os

if not pcall(require, 'luarocks.require') then
  print("Warning: luarocks not found.")
end

pcall(require, 'lfs')
if lfs == nil then
  print("lfs include failed. Test list was not generated.")
  return
end

local lfs = lfs
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
      end
    end
  end
  return dest
end

-- get all library files
local lib_files = find_all_files("lua-nucleo", ".lua")

-- get all test cases
local cases = find_all_files("test/cases", ".lua")

-- check all library files got test cases
print("Test list generation check:")
for i = 1, #lib_files do
  local lib_file = lib_files[i]
  lib_file = lib_file:match("([%w%-_]+).lua")
  local match_found = false
  io.write(lib_file .. ": ")
  lib_file = lib_file:gsub("%-", "%%%-") -- replace "-" with "%-" in names
  for j = 1, #cases do
    local case_j = cases[j]
    if string.match(case_j, "%-" .. lib_file .. "[%-%.]") then
      match_found = true
      io.write(case_j .. "; ")
    end
  end
  if match_found == false then
    print("no tests found.\nTest list generation failed!\n")
    os.remove("test/test-list.lua")
    return nil
  end
  io.write("\n")
end
print("OK\n")

-- write test list
print("Test list file write:")
local file, err = io.open("test/test-list.lua", "w")
file:write("-- all-tests.lua: the list of all tests in the library\n"
        .. "-- This file is generetad by lua-nucleo library\n"
        .. "-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)\n\n"
        .. "return\n{\n")
for i = 1, #cases do
  file:write("  '" .. cases[i]:match("([%w%-_]+).lua") .. "';\n")
end
file:write("}\n")
file:close()
print("OK\n")
