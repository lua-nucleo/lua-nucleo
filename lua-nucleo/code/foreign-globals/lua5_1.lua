--------------------------------------------------------------------------------
--- List of globals defined in Lua 5.1.5
-- @module lua-nucleo.code.foreign-globals.lua5_1
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local GLOBALS =
{
  "_G";
  "_VERSION";
  "assert";
  "collectgarbage";
  "coroutine";
  "debug";
  "dofile";
  "error";
  "gcinfo";
  "getfenv";
  "getmetatable";
  "io";
  "ipairs";
  "load";
  "loadfile";
  "loadstring";
  "math";
  "module";
  "newproxy";
  "next";
  "os";
  "package";
  "pairs";
  "pcall";
  "print";
  "rawequal";
  "rawget";
  "rawset";
  "require";
  "select";
  "setfenv";
  "setmetatable";
  "string";
  "table";
  "tonumber";
  "tostring";
  "type";
  "unpack";
  "xpcall";
}

--------------------------------------------------------------------------------

return
{
  GLOBALS = GLOBALS;
}
