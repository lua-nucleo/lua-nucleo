#! /bin/bash

set -e

echo "----> Generating a list of tests"
lua "test/test-lib/generate-test-list.lua"

echo "----> Creating list-exports"
etc/list-exports/list-exports list_all

echo "----> Generating rockspecs"
lua etc/rockspec/generate.lua scm-1 > rockspec/lua-nucleo-scm-1.rockspec

echo "----> Making rocks"
sudo luarocks make rockspec/lua-nucleo-scm-1.rockspec

echo "----> Restarting multiwatch and LJ2"
sudo killall multiwatch && sudo killall luajit2

echo "----> OK"
