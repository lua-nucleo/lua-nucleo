-- require_and_declare.lua: wrapper around require() that declare()s module names
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local type, assert
    = type, assert

local original_require = require

local require_and_declare
do
  require_and_declare = function(module_name, ...)
    assert(original_require ~= require_and_declare) -- Sanity check
    if declare and type(module_name) == "string" then
      declare(module_name)
    end
    return original_require(module_name, ...)
  end
end

return
{
  require_and_declare = require_and_declare;
}
