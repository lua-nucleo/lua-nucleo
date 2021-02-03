--------------------------------------------------------------------------------
-- 0430-code-foreign-globals-lua5_1.lua: test on foreign globals
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = assert(loadfile('test/test-lib/init/strict-import-as-require.lua'))(...)

local ensure_equals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure_equals'
      }

--------------------------------------------------------------------------------

local test = make_suite("code_foreign_globals_lua5_1")

test:TODO "write tests"

--------------------------------------------------------------------------------

local is_lua_aplicado_shell_found, err =
  pcall(import, 'lua-aplicado/shell.lua')

--------------------------------------------------------------------------------

-- TODO: Add check for reading stderr and stdstr
--       https://github.com/lua-aplicado/lua-aplicado/issues/34
test:BROKEN_IF(not is_lua_aplicado_shell_found)
  'global_variable__PROMPT_error_on_load_in_interactive_mode' (
    function ()
      local shell_write
            = import 'lua-aplicado/shell.lua'
            {
              'shell_write'
            }

      -- NOTE: _PROMPT is created when lua in interactive mode
      local _, msg =
        pcall(shell_write, 'require "lua-nucleo"', "lua", "-i")
      ensure_equals('Lua failed on start in intarective mode', msg, nil)
    end
  )
