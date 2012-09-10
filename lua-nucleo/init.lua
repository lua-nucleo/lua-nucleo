--------------------------------------------------------------------------------
--- Standalone lua-nucleo library initialization
-- @module lua-nucleo.init
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

require 'lua-nucleo.strict'
require 'lua-nucleo.import'
require = import 'lua-nucleo/require_and_declare.lua' { 'require_and_declare' }
