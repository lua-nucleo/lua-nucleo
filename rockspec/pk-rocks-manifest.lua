--------------------------------------------------------------------------------
-- pk-rocks-manifest.lua: PK rocks manifest
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ROCKS =
{
  {
    "rockspec/lua-nucleo-scm-1.rockspec";
    generator =
    {
      "pk-lua-interpreter", "etc/rockspec/generate.lua", "scm-1",
        ">", "rockspec/lua-nucleo-scm-1.rockspec"
    };
  };
}

return
{
  ROCKS = ROCKS;
}
