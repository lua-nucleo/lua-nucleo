--------------------------------------------------------------------------------
--- A simple test suite
-- @module lua-nucleo.suite
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

--dofile('lua-nucleo/strict.lua') -- TODO: sandbox absence problem
if not import then
  dofile('lua-nucleo/import.lua') -- attempt to get it
end

local common_method_list
      = import 'lua-nucleo/factory.lua'
      {
        'common_method_list'
      }

local is_string,
      is_function
      = import 'lua-nucleo/type.lua'
      {
        'is_string',
        'is_function'
      }

local bind_many
      = import 'lua-nucleo/functional.lua'
      {
        'bind_many'
      }

local tifindvalue_nonrecursive
      = import 'lua-nucleo/table-utils.lua'
      {
        'tifindvalue_nonrecursive'
      }

local print, loadfile, xpcall, error, assert, type, next, pairs =
      print, loadfile, xpcall, error, assert, type, next, pairs

local getmetatable, setmetatable
    = getmetatable, setmetatable

local _G = _G

local debug_traceback = debug.traceback
local table_concat, table_insert = table.concat, table.insert

local err_handler = function(err)
  print(debug_traceback(err, 2))
  return err
end

local make_single_test
do
  local with = function(self, decorator)
    assert(type(self) == "table", "bad self")
    assert(type(decorator) == "function", "bad function")

    local decorators = self.decorators_
    table_insert(decorators, 1, decorator)
    return self
  end

  local add_test = function(self, fn, ...)
    assert(type(self) == "table", "bad self")
    assert(type(fn) == "function", "bad callback")

    -- This assertion prevents construction line
    -- test:case "name" (function() ... end) (function() ... end)
    assert(self.called_ == false, "already called")

    -- factories can have more than one argument
    if select("#", ...) > 0 then
      fn = bind_many(fn, ...)
    end

    -- decorate tests in reverse order
    local decorators = self.decorators_
    for i = 1, #decorators do
      fn = decorators[i](fn)
    end

    self.called_ = true
    return self.test_adder_fn_(fn)
  end

  local single_test_mt =
  {
    __call = add_test;
  }

  make_single_test = function(test_adder_fn)
    assert(type(test_adder_fn) == "function", "bad callback")

    return setmetatable(
        {
          with = with;
          add_test = add_test;

          -- public fields

          name = "noname";

          -- fields
          decorators_ = { };
          test_adder_fn_ = test_adder_fn;
          called_ = false;
        },
        single_test_mt
      )
  end
end

-- It's a hackish semi-private method that uses private `suite`
-- properties outside a `suite` object
-- TODO: refactor this in order to not use private properties from
-- outer functions
-- https://github.com/lua-nucleo/lua-nucleo/issues/6
local run = function(self)
  assert(type(self) == "table", "bad self")

  if self.is_completed_ then
    error("suited was already completed")
  end

  print("Running suite", self.name_, self.strict_mode_ and "in STRICT mode")

  local failed_on_first_error = false
  local nok, errs = 0, {}

  local check_output = function(test, ok, err, text, increment)
    increment = increment or 0
    if ok and increment ~= 0 then
      print("OK")
      nok = nok + increment
    elseif not ok then
      errs[#errs + 1] = { name = test.name, err = err }
      if not self.fail_on_first_error_ then
        print("ERR", text)
      else
        errs[#errs + 1] =
        {
          name = "[FAIL ON FIRST ERROR]",
          err = "FAILED AS REQUESTED"
        }
        print("ERR (failing on first error)", text)
        failed_on_first_error = true
        return false
      end
    end
    return true
  end

  for i = 1, #self.tests_ do
    local test = self.tests_[i]
    print("Suite test", test.name)
    local env = { }
    if self.tests_.set_up_ ~= nil then
      local ok, res_up, err_up = xpcall(
          function() self.tests_.set_up_(env) end,
          err_handler
        )
      if
        not check_output(
            test,
            ok and not err_up,
            not ok and res_up or err_up,
            "set up"
          )
      then
        break
      end
    end

    local ok, res, err = xpcall(function() test.fn(env) end, err_handler)
    if
      not check_output(
          test,
          ok and not err,
          not ok and res or err,
          "",
          1
        )
    then
      break
    end

    if self.tests_.tear_down_ ~= nil then
      local ok, res_down, err_down = xpcall(
          function() self.tests_.tear_down_(env) end,
          err_handler
        )
      if
        not check_output(
            test,
            ok and not err_down,
            not ok and res_down or err_down,
            "tear down"
          )
      then
        break
      end
    end
  end

  local todo_messages = nil
  if not failed_on_first_error then
    local imports_set = self.imports_set_
    if imports_set then
      print("Checking suite completeness")
      if #self.tests_ == 0 and #self.todos_ == 0 then
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
      for i = 1, #self.todos_ do
        local todo = self.todos_[i]
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

  local nerr, nskipped = #errs, #self.skipped_

  print("Total tests in suite:", nok + nerr)
  print("Successful:", nok)
  if nskipped > 0 then
    print("Skipped:", nskipped)
  end

  if failed_on_first_error then
    print("Failed on first error")
  end

  if nerr > 0 then
    print("Failed:", nerr)
    local msg = { "Suite `", self.name_, "' failed:\n" }
    for i = 1, #errs do
      local err = errs[i]
      print(err.name, err.err)
      msg[#msg + 1] = " * Test `"
      msg[#msg + 1] = err.name
      msg[#msg + 1] = "': "
      msg[#msg + 1] = err.err
      msg[#msg + 1] = "\n"
    end
    assert(self.error_message_ == nil, "error message was already filled up")
    self.error_message_ = table_concat(msg)
  end

  if todo_messages and not self.strict_mode_ then
    print("\nTODO:")
    print(todo_messages)
  end

  self.error_count_ = nerr
  self.is_completed_ = true
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
    check_name(self, import_name)
    return function(import_name) return tests_for(self, import_name) end
  end

  local group = tests_for -- Useful alias

  local TODO = function(self, msg)
    assert(type(self) == "table", "bad self")
    assert(type(msg) == "string", "bad msg")
    self.todos_[#self.todos_ + 1] = msg
  end

  local BROKEN = function(self, msg)
    -- Behave as TODO, but allow pass "unused" function inside
    assert(type(self) == "table", "bad self")
    assert(type(msg) == "string", "bad msg")
    self:TODO("BROKEN TEST: " .. msg)
    return make_single_test(function(fn)
      assert(type(fn) == "function", "bad callback")
    end)
  end

  local BROKEN_IF = function(self, is_broken)
    assert(type(self) == "table", "bad self")
    assert(type(is_broken) == "boolean", "bad is_broken")

    local mt =
    {
      __call = function(call_self, arg)
        if not is_broken then
          return self(arg)
        end

        if is_broken then
          return BROKEN(
            call_self,
            tostring(call_self.name or arg) .. ": conditionally broken"
          )
        end

        if type(arg) == "string" then
          return call_self:test(arg)
        end

        return call_self(arg)
      end;
      __index = self;
    }

    local result = { }

    if is_broken then
      result.test_for = function(_, name)
        check_name(self, name)
        return BROKEN(
          self,
          tostring(name) .. ": conditionally broken"
        )
      end
    end

    return setmetatable(result, mt)
  end

  local UNTESTED = function(self, import_name)
    assert(type(self) == "table", "bad self")
    assert(type(import_name) == "string", "bad import name")
    check_duplicate(self, import_name)
    check_name(self, import_name)
    self:TODO("write tests for `" .. import_name .. "'")
  end

  local DEPRECATED = function(self, import_name)
    assert(type(self) == "table", "bad self")
    assert(type(import_name) == "string", "bad import name")
    check_duplicate(self, import_name)
    check_name(self, import_name)
    self:TODO(
        "`" .. import_name .. "' is marked as DEPRECATED and won't be tested"
      )
  end

  local SLOW = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_duplicate(self, name)

    return make_single_test(function(fn)
      assert(type(fn) == "function", "bad callback")
      if self.skip_slow_tests_ then
        print("`" .. name .. "' SKIPPED because marked as SLOW")
        self.skipped_[#self.skipped_ + 1] = { name = name, fn = fn }
      else
        self.tests_[#self.tests_ + 1] = { name = name, fn = fn }
      end
    end)
  end

  local test_for = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_name(self, name)
    local test = self:test(name)

    local mt = getmetatable(test)
    mt.__index = self
    setmetatable(test, mt)

    return test
  end

  local set_up = function(self, fn)
    assert(type(self) == "table", "bad self")
    assert(type(fn) == "function", "bad function")
    assert(self.tests_.set_up_ == nil, "set_up duplication")
    self.tests_.set_up_ = fn
  end

  local tear_down = function(self, fn)
    assert(type(self) == "table", "bad self")
    assert(type(fn) == "function", "bad function")
    assert(self.tests_.tear_down_ == nil, "tear_down duplication")
    self.tests_.tear_down_ = fn
  end

  local test = function(self, name)
    assert(type(self) == "table", "bad self")
    assert(type(name) == "string", "bad import name")
    check_duplicate(self, name)

    local result = make_single_test(function(fn)
      assert(type(fn) == "function", "bad callback")
      -- filter tests
      -- NB: we explicitly let simple list of names so that one could
      --     specify several runs of the same test, to ensure e.g.
      --     invariance
      if not self.relevant_test_names_ or
         tifindvalue_nonrecursive(self.relevant_test_names_, name)
      then
        self.tests_[#self.tests_ + 1] = { name = name, fn = fn }
      else
      end
    end)

    result.name = name

    return result
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

    return make_single_test(function(factory, ...)
      assert(type(factory) == "function", "bad factory")
      -- pass clean environment to decorated factory, own arguments of factory
      -- (if any) protected by bind_many inside make_single_test constructor
      add_methods(self, common_method_list(factory, { }))
    end)
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

  local check_fail_on_first_error = function(self)
    return self.fail_on_first_error_
  end

  local in_strict_mode = function(self)
    return self.strict_mode_
  end

  local case = test -- Useful alias

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

  local set_skip_slow_tests = function(self, flag)
    assert(type(self) == "table", "bad self")
    assert(type(flag) == "boolean", "bad flag")

    self.skip_slow_tests_ = flag
  end

  local set_relevant_test_names = function(self, names)
    assert(type(self) == "table", "bad self")
    assert(type(names) == "table" or names == false, "bad names")

    self.relevant_test_names_ = names
  end

  local suite_mt =
  {
    __call = test;
  }

  local get_error_count = function(self)
    return self.error_count_
  end

  local get_error_message = function(self)
    return self.error_message_
  end

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
          test = test;
          case = case; -- Note this is an alias for test().
          set_up = set_up;
          tear_down = tear_down;
          set_strict_mode = set_strict_mode;
          in_strict_mode = in_strict_mode;
          -- TODO: test set_fail_on_first_error
          -- https://github.com/lua-nucleo/lua-nucleo/issues/4
          set_fail_on_first_error = set_fail_on_first_error;
          set_skip_slow_tests = set_skip_slow_tests;
          set_relevant_test_names = set_relevant_test_names;
          UNTESTED = UNTESTED;
          DEPRECATED = DEPRECATED;
          TODO = TODO;
          BROKEN = BROKEN;
          BROKEN_IF = BROKEN_IF;
          SLOW = SLOW;
          factory = factory;
          method = method;
          methods = methods;
          get_error_count = get_error_count;
          get_error_message = get_error_message;
          --
          name_ = name;
          strict_mode_ = false;
          fail_on_first_error_ = false;
          imports_set_ = imports_set;
          current_group_ = "";
          skip_slow_tests_ = false;
          tests_ = { };
          test_names_ = { };
          relevant_test_names_ = false;
          todos_ = { };
          skipped_ = { };
          --
          error_count_ = 0;
          error_message_ = nil;
          is_completed_ = false;
        },
        suite_mt
      )
  end
end

local run_test = function(target, parameters_list)
  local result, stage, msg = true, nil, nil

  -- TODO: Remove. Legacy code compatibility
  if type(parameters_list) == "boolean" then
    parameters_list =
    {
      strict_mode = parameters_list;
      seed_value = 12345;
    }
  end

  local strict_mode = not not parameters_list.strict_mode
  local fail_on_first_error = not not parameters_list.fail_on_first_error
  local skip_slow_tests = not not parameters_list.quick
  local relevant_test_names = parameters_list.names
  local suite

  local suite_maker = function(...)
    if suite ~= nil then
      error("suite was already initialized")
    else
      suite = make_suite(...)
      suite:set_strict_mode(strict_mode)
      suite:set_fail_on_first_error(fail_on_first_error)
      suite:set_skip_slow_tests(skip_slow_tests)
      if relevant_test_names then
        suite:set_relevant_test_names(relevant_test_names)
      end
      return suite
    end
  end

  local gmt = getmetatable(_G) -- Preserve metatable
  math.randomseed(parameters_list.seed_value)

  local fn, load_err
  if is_function(target) then
    fn = target
  elseif is_string(target) then
    fn, load_err = loadfile(target)
  else
    error("target should be filename or function")
  end

  if not fn then
    result, stage, msg = false, "load", load_err
  else
    local ok, res = xpcall(
        function()
          fn(suite_maker)

          if suite ~= nil then
            run(suite)
          else
            error("suite wasn't initialized")
          end
        end,
        err_handler
      )
    if not ok then
      result, stage, msg = false, "run", res
    elseif suite:get_error_count() > 0 then
      result, stage, msg = false, "run", suite:get_error_message()
    end
    uninstall_strict_mode_()
  end

  setmetatable(_G, gmt)

  return result, stage, msg
end

local run_tests = function(names, parameters_list)
  local nok, errs = 0, {}

  -- TODO: Remove. Legacy code compatibility
  if type(parameters_list) == "boolean" then
    parameters_list =
    {
      strict_mode = parameters_list;
      seed_value = 12345;
    }
  end

  local strict_mode = not not parameters_list.strict_mode
  local fail_on_first_error = not not parameters_list.fail_on_first_error

  if strict_mode then
    print("Enabling STRICT mode")
  else
    print("STRICT mode is disabled")
  end

  for i = 1, #names do
    local name = names[i]
    print("Running test", name)
    io.flush()
    -- TODO: somehow get suite here, to extract #suite.skipped_
    local res, stage, err, todo = run_test(name, parameters_list)
    io.flush()
    if res then
      print("OK")
      nok = nok + 1
    else
      print("ERR", stage)
      errs[#errs + 1] = { name = name, stage = stage, err = err }
      if fail_on_first_error then
        break
      end
    end
  end

  local nerr = #errs

  print()
  print("--------------------------------------------------------------------------------")
  print()
  print("Finished running tests.")
  print()
  print("Total tests:", nok + nerr)
  print("Successful:", nok)
  if nerr > 0 then
    print("Failed:", nerr)
    print()
    print("Dumping error messages from failing tests:")
    print()
    print("--------------------------------------------------------------------------------")
    print()
    for i = 1, nerr do
      print("["..errs[i].stage.."]", errs[i].name, errs[i].err)
    end
  end


  return nok, errs
end

return
{
  run_tests = run_tests;
  run_test = run_test;
  make_suite = make_suite;
}
