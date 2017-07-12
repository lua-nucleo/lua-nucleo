#! /bin/bash

set -euo pipefail

echo "----> Generating a list of tests"
lua "test/test-lib/generate-test-list.lua" "lua-nucleo test/test-list.lua .lua test/low-level test/suite test/cases"

if luarocks show pk-tools.list-exports; then
  echo "----> Creating list-exports"
  etc/list-exports/list-exports list_all
else
  echo "----> No list-exports installed, skipping"
fi

echo "----> Generating rockspecs"
lua etc/rockspec/generate.lua scm-1 > rockspec/lua-nucleo-scm-1.rockspec

echo "----> Remove a rock"
sudo luarocks remove --force lua-nucleo || true

echo "----> Making rocks"
sudo luarocks make rockspec/lua-nucleo-scm-1.rockspec

case "${1:-}" in
  --no-restart) ;; # Do nothing
  *)
    echo "----> Restarting multiwatch and LJ2"
    sudo killall multiwatch || true ; sudo killall luajit2 || true
  ;;
esac

echo "----> OK"
