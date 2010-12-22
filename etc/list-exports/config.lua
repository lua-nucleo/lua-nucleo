--------------------------------------------------------------------------------
-- config.lua: list-exports configuration
--------------------------------------------------------------------------------
-- Note that PROJECT_PATH is defined in the environment
--------------------------------------------------------------------------------

common =
{
  PROJECT_PATH = PROJECT_PATH;

  exports =
  {
    exports_dir = PROJECT_PATH .. "/lua-nucleo/code/";
    profiles_dir = PROJECT_PATH .. "/lua-nucleo/code/";

    sources =
    {
      {
        sources_dir = PROJECT_PATH;
        root_dir_only = "lua-nucleo/";
        profile_filename = "profile.lua";
        out_filename = "exports.lua";
      };
    };
  };
}

--------------------------------------------------------------------------------

list_exports =
{
  action =
  {
    name = "help";
    param =
    {
      -- No parameters
    };
  };
};
