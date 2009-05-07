-- suite.lua -- a simple test suite
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local print, loadfile, xpcall, error, ipairs, assert, type =
      print, loadfile, xpcall, error, ipairs, assert, type
local debug_traceback = debug.traceback
local table_concat = table.concat

local err_handler = function(err)
  print(debug_traceback(err, 2))
  return err
end

local make_suite
do
  local suite_test = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad name")
    assert(not self.tests_[name])
    return function(fn)
      assert(type(fn) == "function", "bad callback")
      self.tests_[#self.tests_ + 1] = { name = name, fn = fn }
    end
  end

  local suite_run = function(self)
    assert(type(self) == "table", "bad self")

    print("Running suite", self.name_)

    local nok, errs = 0, {}
    for i, test in ipairs(self.tests_) do
      print("Suite test", test.name)
      local res, err = xpcall(function() test.fn() end, err_handler)
      if res then
        print("OK")
        nok = nok + 1
      else
        print("ERR")
        errs[#errs + 1] = { name = test.name, err = err }
      end
    end

    local nerr = #errs

    print("Total tests in suite:", nok + nerr)
    print("Successful:", nok)

    local msg

    if nerr > 0 then
      print("Failed:", nerr)
      msg = {"Suite `", self.name_, "' failed:\n"}
      for i, err in ipairs(errs) do
        print(err.name, err.err)
        msg[#msg + 1] = " * Test `"
        msg[#msg + 1] = err.name
        msg[#msg + 1] = "': "
        msg[#msg + 1] = err.err
        msg[#msg + 1] = "\n"
      end
      msg = table_concat(msg)
    end

    return nerr == 0, msg
  end

  local suite_mt =
  {
    __call = suite_test;
  }

  make_suite = function(name)
    assert(type(name) == "string", "bad name")
    return setmetatable(
        {
          test = suite_test;
          run = suite_run;
          --
          name_ = name;
          tests_ = {};
        },
        suite_mt
      )
  end
end

local run_test = function(name)
  local result, stage, msg = true, nil, nil

  local gmt = getmetatable(_G) -- Preserve metatable

  local fn, load_err = loadfile("test/"..name..".lua")
  if not fn then
    result, stage, msg = false, "load", load_err
  else
    local res, run_err = xpcall(
        function() fn(make_suite) end,
        err_handler
      )

    if not res then
      result, stage, msg = false, "run", run_err
    end
  end

  setmetatable(_G, gmt)

  return result, stage, msg
end

local run_tests = function(names)
  local nok, errs = 0, {}
  for _, name in ipairs(names) do
    print("Running test", name)
    local res, stage, err = run_test(name)
    if res then
      print("OK")
      nok = nok + 1
    else
      print("ERR", stage)
      errs[#errs + 1] = { name = name, stage = stage, err = err }
    end
  end

  local nerr = #errs

  print()
  print("Total tests:", nok + nerr)
  print("Successful:", nok)
  if nerr > 0 then
    print()
    print("Failed:", nerr)
    for i, err in ipairs(errs) do
      print("["..err.stage.."]", err.name, err.err)
    end
  end
end

return
{
  run_tests = run_tests;
  make_suite = make_suite;
}
