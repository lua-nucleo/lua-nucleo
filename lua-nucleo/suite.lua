-- suite.lua: a simple test suite
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local print, loadfile, xpcall, error, ipairs, assert, type, next, pairs =
      print, loadfile, xpcall, error, ipairs, assert, type, next, pairs

local getmetatable, setmetatable
    = getmetatable, setmetatable

local _G = _G -- TODO: ?!

local debug_traceback = debug.traceback
local table_concat = table.concat

local err_handler = function(err)
  print(debug_traceback(err, 2))
  return err
end

local common_method_list = function(factory, ...)
  assert(type(factory) == "function", "`function' expected")
  local factory_return = factory(...)
  assert(type(factory_return) == "table", "`table' expected")
  local method_list = {}
  for k, v in pairs(factory_return) do
    if type(v) == "function" then
      if type(k) == "string" then
        if k:sub(-1) ~= '_' then
          method_list[#method_list + 1] = k
        end
      else
        error("non-string key for function value")
      end
    end
  end
  return method_list
end

local make_suite
do
  local check_name = function(self, import_name)
    local imports_set = self.imports_set_
    if imports_set then
      if not imports_set[import_name] then
        error("suite: unknown import `" .. import_name .. "'", 2)
      end
      imports_set[import_name] = nil
    end
  end

  local check_duplicate = function(self, name)
    if self.test_names_[name] == true then
      error("test name duplicated: " .. name, 3)
    end
    self.test_names_[name] = true
  end

  local function tests_for(self, import_name)
    assert(type(self) == "table", "bad self")
    assert(type(import_name) == "string", "bad import name")
    check_duplicate(self, import_name)
    check_name(self, import_name)
    return function(import_name) return tests_for(self, import_name) end
  end

  local group = tests_for -- Useful alias

  local TODO = function(self, msg)
    assert(type(self) == "table", "bad self")
    assert(type(msg) == "string", "bad msg")
    self.todos_[#self.todos_ + 1] = msg
  end

  local UNTESTED = function(self, import_name)
    assert(type(self) == "table", "bad self")
    assert(type(import_name) == "string", "bad import name")
    check_duplicate(self, import_name)
    check_name(self, import_name)
    self:TODO("write tests for `" .. import_name .. "'")
  end

  local test_for = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_name(self, name)
    return self:test(name)
  end

  local test = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_duplicate(self, name)

    return function(fn)
      assert(type(fn) == "function", "bad callback")
      self.tests_[#self.tests_ + 1] = { name = name, fn = fn }
    end
  end

  local add_methods = function(self, methods_list)
    assert(type(methods_list) == "table", "bad methods list")
    local imports_set = self.imports_set_
    for i = 1, #methods_list do
      local method = methods_list[i]
      assert(not imports_set[method], "duplicate test name")
      local method_full_name = self.current_group_ .. ":" .. method
      assert(not imports_set[method_full_name], "duplicate test name")
      imports_set[method_full_name] = true

    end
  end

  local factory = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_duplicate(self, name)
    check_name(self, name)
    self.current_group_ = name

    return function(factory, ...)
      if type(factory) == "function" then
        add_methods(self, common_method_list(factory, ...))
      elseif type(factory) == "table" then
        add_methods(self, factory)
      else
        error("expected function or table")
      end
    end
  end

  local method = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_duplicate(self, name)

    local method_full_name = self.current_group_ .. ":" .. name
    -- no duplicate check on full_name here as it will be checked in :test
    check_name(self, method_full_name)
    return self:test(method_full_name)
  end

  local function methods(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    local method_full_name = self.current_group_ .. ":" .. name
    check_duplicate(self, name)
    check_duplicate(self, method_full_name)
    check_name(self, method_full_name)
    return function(name) return methods(self, name) end
  end

  local in_strict_mode = function(self)
    return self.strict_mode_
  end

  local case = test -- Useful alias

  local run = function(self)
    assert(type(self) == "table", "bad self")

    print("Running suite", self.name_, self.strict_mode_ and "in STRICT mode")

    local failed_on_first_error = false

    local nok, errs = 0, {}
    for i, test in ipairs(self.tests_) do
      print("Suite test", test.name)
      local res, err = xpcall(function() test.fn() end, err_handler)
      if res then
        print("OK")
        nok = nok + 1
      else
        errs[#errs + 1] = { name = test.name, err = err }
        if not self.fail_on_first_error_ then
          print("ERR")
        else
          errs[#errs + 1] = { name = "[FAIL ON FIRST ERROR]", err = "FAILED AS REQUESTED" }
          print("ERR (failing on first error)")
          failed_on_first_error = true
          break
        end
      end
    end

    local todo_messages = nil
    if not failed_on_first_error then
      local imports_set = self.imports_set_
      if imports_set then
        print("Checking suite completeness")
        if #self.tests_ == 0 then
          print("ERR")
          errs[#errs + 1] = { name = "[completeness check]", err = "empty" }
        elseif next(imports_set) == nil then
          print("OK")
          nok = nok + 1
        else
          print("ERR")

          local list = { }
          for name, _ in pairs(imports_set) do
            list[#list + 1] = name
          end

          errs[#errs + 1] =
          {
            name = "[completeness check]";
            err = "detected untested imports: "
              .. table_concat(list, ", ")
              ;
          }
        end
      end

      if #self.todos_ > 0 then
        todo_messages = { }
        for i, todo in ipairs(self.todos_) do
          todo_messages[#todo_messages + 1] = "   -- "
          todo_messages[#todo_messages + 1] = todo
          todo_messages[#todo_messages + 1] = "\n"
        end
        todo_messages = table_concat(todo_messages)

        if self.strict_mode_ then
          errs[#errs + 1] =
          {
            name = "[STRICT MODE]";
            err = "detected TODOs:\n" .. todo_messages;
          }
        end
      end
    end

    local nerr = #errs

    print("Total tests in suite:", nok + nerr)
    print("Successful:", nok)

    if failed_on_first_error then
      print("Failed on first error")
    end

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

    if todo_messages and not self.strict_mode_ then
      print("\nTODO:")
      print(todo_messages)
    end

    if nerr ~= 0 then
      return nil, msg
    end

    return true
  end

  local set_strict_mode = function(self, flag)
    assert(type(self) == "table", "bad self")
    assert(type(flag) == "boolean", "bad flag")

    self.strict_mode_ = flag
  end

  local set_fail_on_first_error = function(self, flag)
    assert(type(self) == "table", "bad self")
    assert(type(flag) == "boolean", "bad flag")

    self.fail_on_first_error_ = flag
  end

  local suite_mt =
  {
    __call = test;
  }

  make_suite = function(name, imports)
    assert(type(name) == "string", "bad name")

    local imports_set = false
    if imports then
      assert(type(imports) == "table", "bad imports")

      -- Note: This code is too low level to use tkeysvalues().
      imports_set = { }
      for name, _ in pairs(imports) do
        -- NOTE: If you ever need non-string imports,
        --       fix table_concat() in completeness check above first.
        assert(type(name) == "string", "non-string imports")
        imports_set[name] = true
      end
    end

    return setmetatable(
        {
          tests_for = tests_for;
          group = group; -- Note this is an alias for tests_for().
          test_for = test_for;
          in_strict_mode = in_strict_mode;
          test = test;
          case = case; -- Note this is an alias for test().
          run = run;
          set_strict_mode = set_strict_mode;
          set_fail_on_first_error = set_fail_on_first_error; -- TODO: Test this!
          UNTESTED = UNTESTED;
          TODO = TODO;
          factory = factory;
          method = method;
          methods = methods;
          --
          name_ = name;
          strict_mode_ = false;
          fail_on_first_error_ = false;
          imports_set_ = imports_set;
          current_group_ = "";
          tests_ = {};
          test_names_ = {};
          todos_ = {};
        },
        suite_mt
      )
  end
end

local make_suite_strict = function(...)
  local suite = make_suite(...)
  suite:set_strict_mode(true)
  return suite
end

local make_suite_nonstrict = function(...)
  local suite = make_suite(...)
  suite:set_strict_mode(false)
  return suite
end

local run_test = function(name, strict_mode)
  local result, stage, msg = true, nil, nil

  local gmt = getmetatable(_G) -- Preserve metatable

  local fn, load_err = loadfile(name)
  if not fn then
    result, stage, msg = false, "load", load_err
  else
    local suite_maker = strict_mode
      and make_suite_strict
       or make_suite_nonstrict

    local res, run_err = xpcall(
        function() fn(suite_maker) end,
        err_handler
      )

    if not res then
      result, stage, msg = false, "run", run_err
    end
  end

  setmetatable(_G, gmt)

  return result, stage, msg
end

local run_tests = function(names, strict_mode)
  local nok, errs = 0, {}

  if strict_mode then
    print("Enabling STRICT mode")
  else
    print("STRICT mode is disabled")
  end

  for _, name in ipairs(names) do
    print("Running test", name)
    local res, stage, err, todo = run_test(name, strict_mode)
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

  return nok, errs
end

return
{
  run_tests = run_tests;
  make_suite = make_suite;
  common_method_list = common_method_list;
}
