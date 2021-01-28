--------------------------------------------------------------------------------
-- test.lua: tests for all modules of the library
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- WARNING: do not use import in this file for the test purity reasons.
local run_tests = assert(assert(assert(loadfile('lua-nucleo/suite.lua'))()).run_tests)


-- TODO: Also preserve random number generator's seed
--       (save it and restore between suites)
-- https://github.com/lua-nucleo/lua-nucleo/issues/10

local tests_pr = assert(assert(loadfile('test/test-list.lua'))())

local parameters_list = {}
local n = 1
-- TODO: we need to implement input params parser and default values injector
-- https://github.com/lua-nucleo/lua-nucleo/issues/9
if select(n, ...) == "--strict" then
  parameters_list.strict_mode = true
  n = 2
else
  parameters_list.strict_mode = false
end
parameters_list.seed_value = 12345


local pattern = select(n, ...) or ""
assert(type(pattern) == "string")

local low_level_tests = { }
local suite_tests = { }
local standard_tests = { }
for i = 1, #tests_pr do
  local info = tests_pr[i]
  -- Checking directly to avoid escaping special characters (like '-')
  -- when running specific test
  if info.path:match(pattern) then
    if info.type == "low-level" then
      low_level_tests[#low_level_tests + 1] = info.path
    else
      if info.type == "suite" then
        suite_tests[#suite_tests + 1] = info.path
      else
        standard_tests[#standard_tests + 1] = info.path
      end
    end
  end
end

if #low_level_tests == 0 and #suite_tests == 0 and #standard_tests == 0 then
  error("no tests match pattern `" .. pattern .. "'")
end

if pattern ~= "" then
  print(
      "Running " .. (#low_level_tests + #suite_tests + #standard_tests)
   .. " test(s) matching pattern `" .. pattern .. "'"
     )
end

local run_low_level_tests = function(test_list)
  local is_shell_found, shell = pcall(require, "lua-aplicado.shell")
  if not is_shell_found then
    local err = shell
    local error_message = "failed to link up with lua-aplicado:\n" .. err
    if parameters_list.strict_mode then
      error(error_message)
    else
      print(
          "WARNING: " .. error_message .. "\n"
          .. "skipping low-level tests"
        )
    end

    return 0, { }
  end

  local shell_read = assert(shell.shell_read)

  local get_interpreter = function(name)
    local ok, lua = pcall(shell_read, "which", name)

    if ok then
      return lua:sub(1, #lua - 1) -- remove trailing newline
    else
      local err = lua
      return nil, err
    end
  end

  -- TODO: use current running interpreter path for launch low-level tests
  -- https://github.com/lua-nucleo/lua-nucleo/issues/11
  local lua
  local err = {}
  if jit ~= nil then
    lua, err["luajit2"] = get_interpreter("luajit2")
    if not lua then
      lua, err["luajit"] = get_interpreter("luajit")
    end
  else
    lua, err["lua"] = get_interpreter("lua")
  end

  if not lua then
    for name, msg in pairs(err) do
      io.stderr:write("Can't find interpreter " .. name .. " : " .. tostring(msg))
    end
    error("Interpreter not found")
  end

  local errors = { }
  for i = 1, #test_list do
    local test_path = test_list[i]

    local ok, output = pcall(shell_read, lua, test_path)

    if ok then
      print(output)
    else
      errors[#errors + 1] = test_path .. ": " .. output
    end
  end

  return #errors == 0, errors
end

if #suite_tests > 0 then
  for i = 1, #suite_tests do
    low_level_tests[#low_level_tests + 1] = suite_tests[i]
  end
end

local is_low_level_success,
      low_level_errors
      = run_low_level_tests(low_level_tests)

print("--------------------------------------------------------------------------------")
print("------> Low-level and suite tests completed")
print("--------------------------------------------------------------------------------")
if #standard_tests > 0 then
  run_tests(standard_tests, parameters_list)
end

print()
print("--------------------------------------------------------------------------------")
print("------> Low-level and suite tests info")
print("--------------------------------------------------------------------------------")
print()
print("Total low-level and suite tests:", #low_level_tests)
print("Successful low-level and suite:", #low_level_tests - #low_level_errors)

if #low_level_errors > 0 then
  print("Failed low-level and suite:", #low_level_errors)
  print()
  print("Dumping error messages from failing tests:")
  print()
  print("--------------------------------------------------------------------------------")
  print()
  for i = 1, #low_level_errors do
    print(low_level_errors[i])
  end
  print()
  print("--------------------------------------------------------------------------------")
  print("--- End of dumping error messages from failing tests ---------------------------")
  print("--------------------------------------------------------------------------------")
  print()
end
