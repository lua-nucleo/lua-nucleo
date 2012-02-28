--------------------------------------------------------------------------------
-- luajit2.lua: list of globals defined in LuaJIT 2 beta 3
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Update this on LJ2 release

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
