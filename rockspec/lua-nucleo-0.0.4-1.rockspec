package = "lua-nucleo"
version = "0.0.4-1"
source = {
   url = "git://github.com/lua-nucleo/lua-nucleo.git",
   branch = "v0.0.4"
}
description = {
   summary = "A random collection of core and utility level Lua libraries",
   homepage = "http://github.com/lua-nucleo/lua-nucleo",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "none",
   install = {
      lua = {
         ["lua-nucleo.algorithm"] = "lua-nucleo/algorithm.lua";
         ["lua-nucleo.args"] = "lua-nucleo/args.lua";
         ["lua-nucleo.assert"] = "lua-nucleo/assert.lua";
         ["lua-nucleo.checker"] = "lua-nucleo/checker.lua";
         ["lua-nucleo.code.exports"] = "lua-nucleo/code/exports.lua";
         ["lua-nucleo.code.foreign-globals.lua5_1"] = "lua-nucleo/code/foreign-globals/lua5_1.lua";
         ["lua-nucleo.code.foreign-globals.luajit2"] = "lua-nucleo/code/foreign-globals/luajit2.lua";
         ["lua-nucleo.code.globals"] = "lua-nucleo/code/globals.lua";
         ["lua-nucleo.code.profile"] = "lua-nucleo/code/profile.lua";
         ["lua-nucleo.coro"] = "lua-nucleo/coro.lua";
         ["lua-nucleo.deque"] = "lua-nucleo/deque.lua";
         ["lua-nucleo.ensure"] = "lua-nucleo/ensure.lua";
         ["lua-nucleo.factory"] = "lua-nucleo/factory.lua";
         ["lua-nucleo.functional"] = "lua-nucleo/functional.lua";
         ["lua-nucleo.import_as_require"] = "lua-nucleo/import_as_require.lua";
         ["lua-nucleo.language"] = "lua-nucleo/language.lua";
         ["lua-nucleo.log"] = "lua-nucleo/log.lua";
         ["lua-nucleo.math"] = "lua-nucleo/math.lua";
         ["lua-nucleo.misc"] = "lua-nucleo/misc.lua";
         ["lua-nucleo.module"] = "lua-nucleo/module.lua";
         ["lua-nucleo.ordered_named_cat_manager"] = "lua-nucleo/ordered_named_cat_manager.lua";
         ["lua-nucleo.pcall"] = "lua-nucleo/pcall.lua";
         ["lua-nucleo.prettifier"] = "lua-nucleo/prettifier.lua";
         ["lua-nucleo.priority_queue"] = "lua-nucleo/priority_queue.lua";
         ["lua-nucleo.random"] = "lua-nucleo/random.lua";
         ["lua-nucleo.require_and_declare"] = "lua-nucleo/require_and_declare.lua";
         ["lua-nucleo.sandbox"] = "lua-nucleo/sandbox.lua";
         ["lua-nucleo.scoped_cat_tree_manager"] = "lua-nucleo/scoped_cat_tree_manager.lua";
         ["lua-nucleo.stack_with_factory"] = "lua-nucleo/stack_with_factory.lua";
         ["lua-nucleo.strict"] = "lua-nucleo/strict.lua";
         ["lua-nucleo.string"] = "lua-nucleo/string.lua";
         ["lua-nucleo.suite"] = "lua-nucleo/suite.lua";
         ["lua-nucleo.table-utils"] = "lua-nucleo/table-utils.lua";
         ["lua-nucleo.table"] = "lua-nucleo/table.lua";
         ["lua-nucleo.tdeepequals"] = "lua-nucleo/tdeepequals.lua";
         ["lua-nucleo.timed_queue"] = "lua-nucleo/timed_queue.lua";
         ["lua-nucleo.timestamp"] = "lua-nucleo/timestamp.lua";
         ["lua-nucleo.tpretty"] = "lua-nucleo/tpretty.lua";
         ["lua-nucleo.tserialize"] = "lua-nucleo/tserialize.lua";
         ["lua-nucleo.tstr"] = "lua-nucleo/tstr.lua";
         ["lua-nucleo.type"] = "lua-nucleo/type.lua";
         ["lua-nucleo.typeassert"] = "lua-nucleo/typeassert.lua";
         ["lua-nucleo.util.anim.interpolator"] = "lua-nucleo/util/anim/interpolator.lua";
      }
   }
}
