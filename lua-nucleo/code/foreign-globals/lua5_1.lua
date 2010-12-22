--------------------------------------------------------------------------------
-- lua5.1.lua: list of globals defined in Lua 5.1.4
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
