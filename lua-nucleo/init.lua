--------------------------------------------------------------------------------
--- Standalone lua-nucleo library initialization
-- @module lua-nucleo.init
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

require 'lua-nucleo.strict'
require 'lua-nucleo.import'
require = import 'lua-nucleo/require_and_declare.lua' { 'require_and_declare' }

return
{
  _VERSION = '1.1.0';
  _URL = 'https://github.com/lua-nucleo/lua-nucleo';
  _COPYRIGHT = 'Copyright (C) 2009-2021 Lua-Núcleo authors';
  _LICENSE = 'MIT (http://raw.githubusercontent.com/'
          .. 'lua-nucleo/lua-nucleo/master/COPYRIGHT)';
  _DESCRIPTION = 'A random collection of core and utility level Lua libraries';
}
