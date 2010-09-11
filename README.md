Lua-Núcleo – A random collection of core and utility level Lua libraries
========================================================================

This library is still in its embryonic phase.
An appropriate description would be added later.

See the copyright information in the file named `COPYRIGHT`.

Dependencies
------------

Lua-Núcleo itself does not have external dependencies
except for Lua 5.1 itself.

The tests are dependent on luafilesystem:

  sudo luarocks install luafilesystem

List of cases will not be updated without this module,
but you should be able to run tests themselves.

Installation
------------

If you're in a require-friendly environment, you may install lua-nucleo
from luarocks:

    luarocks install \
        lua-nucleo \
        --from=http://luarocks.org/repositories/rocks-cvs

Otherwise just copy lua-nucleo directory whereever is comfortable.

Initialization with require()
-----------------------------

To use lua-nucleo in require-friendly environment, do as follows:

    require 'lua-nucleo.module'

This assumes that lua-nucleo directory is somewhere in the `package.path`

Note that you may also want to enable the strict mode
(aka the Global Environment Protection):

    require 'lua-nucleo.strict'

For all other lua-nucleo files, use `import()`.

Initialization without require()
--------------------------------

Set `CODE_ROOT` to path to lua-nucleo directory.

    dofile(CODE_ROOT..'lua-nucleo/strict.lua')
    assert(loadfile(CODE_ROOT..'lua-nucleo/import.lua'))(CODE_ROOT)

After that use `import()`.
