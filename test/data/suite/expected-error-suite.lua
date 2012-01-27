-- expected-error-suite.lua: a simple test suite with expected error to test run_tests() and fail_on_first_error
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local make_suite = select(1, ...)

local test = make_suite("expected-error-suite")

test "test-expected-error" (function() 
  error("expected error")
end)

assert(test:run())

