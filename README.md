Lua-Núcleo – A random collection of core and utility level Lua libraries
========================================================================

See the copyright information in the file named `COPYRIGHT`.

Dependencies
------------

Lua-Núcleo itself does not have external dependencies
except for Lua 5.1 itself.

The tests are dependent on `luafilesystem` and `lua-aplicado`:

    sudo luarocks install luafilesystem
    sudo luarocks install lua-aplicado

List of cases will not be updated without  `luafilesystem`,
but you should be able to run tests themselves.
Low-level tests can't be executed without `lua-aplicado`.

Installation
------------

If you're in a require-friendly environment, you may install lua-nucleo
from luarocks (http://www.luarocks.org):

    luarocks install lua-nucleo

Or, if you want to get the most current code, use rocks-cvs version:

    luarocks install \
        lua-nucleo \
        --from=http://luarocks.org/repositories/rocks-cvs

Otherwise just copy lua-nucleo directory whereever is comfortable.

Initialization with require()
-----------------------------

To use lua-nucleo in require-friendly environment, do as follows:

    require 'lua-nucleo'

This assumes that lua-nucleo directory is somewhere in the `package.path`

Note that it will enable the strict mode
(aka the Global Environment Protection)

If you definitely want to use lua-nucleo without strict mode, please
use instead:

        require 'lua-nucleo.import'

For all other lua-nucleo files with and without strict mode, use `import()`.

Note that if you want to keep using `require()`,
you may replace in your code

    local foo, bar = import 'lua-nucleo/baz/quo.lua' { 'foo', 'bar' }

with

    local quo = require 'lua-nucleo.baz.quo'
    local foo, bar = quo.foo, quo.bar

Initialization without require()
--------------------------------

Set `CODE_ROOT` Lua variable to path to lua-nucleo directory.

    dofile(CODE_ROOT..'lua-nucleo/strict.lua')
    assert(loadfile(CODE_ROOT..'lua-nucleo/import.lua'))(CODE_ROOT)

After that use `import()`.

Documentation
-------------

Sorry, the documentation for the project is not available at this point.
Read the source and tests.

TODO
----

See file named `TODO`.

Support
-------

Post your questions to the Lua mailing list: http://www.lua.org/lua-l.html
