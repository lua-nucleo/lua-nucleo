--------------------------------------------------------------------------------
--- List of globals defined in LuaJIT 2.0.2
-- @module lua-nucleo.code.foreign-globals.luajit2
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Update this on LJ2 release
-- GH#3 - https://github.com/lua-nucleo/lua-nucleo/issues/3

local GLOBALS =
{
  "_G";
  "_VERSION";
  "assert";
  "bit";
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
  "jit";
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
