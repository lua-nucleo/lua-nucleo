-- 0300-generate-test-list.lua: tests for test list generation
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = assert(loadfile('test/test-lib/init/strict-lfs.lua'))(...)

-- TODO: write tests here
local test = make_suite("generate-test-list", { })
test "generate-test-list" (function()
  -- delete file if exist
  local file, err = io.open("test/data/generate-test-list/test-list-standard.lua", "r")
  if err then error("Error:" .. err) end
  local standard_file_content = file:read("*all")
  file:close()

  os.remove("test/data/generate-test-list/test-list.lua")
  loadfile('test/test-lib/generate-test-list.lua')(
      "test/data/generate-test-list/lib " ..
      "test/data/generate-test-list/cases " ..
      "test/data/generate-test-list/test-list.lua")

  local file, err = io.open("test/data/generate-test-list/test-list.lua", "r")
  if err then error("Error:" .. err) end
  local generated_file_content = file:read("*all")
  file:close()
  if standard_file_content ~= generated_file_content then
    error("Generated file doesnt match standard")
  end
end)

--------------------------------------------------------------------------------
assert(test:run())
