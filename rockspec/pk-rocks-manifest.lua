--------------------------------------------------------------------------------
-- pk-rocks-manifest.lua: PK rocks manifest
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
