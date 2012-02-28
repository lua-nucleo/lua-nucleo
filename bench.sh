#!/bin/sh

#-------------------------------------------------------------------------------
# bench.sh: script that starts benchmarks
# This file is a part of lua-nucleo library
# Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
#-------------------------------------------------------------------------------

echo "=====BEGINNING LUA-NUCLEO BENCHMARKS====="
echo "========================================="
echo "==========TSERIALIZE BENCHMARKS=========="
echo "========================================="
echo "1. Moderate amount(~3-4KBytes) of simple syntetic data"
bench/kbench.sh 'bench/bench.lua bench/tserializebench.lua ' 1e3 2>&1 |  luajit -O bench/kbenchparse.lua
echo "2. Simple recursive table"
bench/kbench.sh 'bench/bench.lua bench/tserializebench_recursive.lua ' 1e6 2>&1 |  luajit -O bench/kbenchparse.lua
echo "3. Random generated data"
bench/kbench.sh 'bench/bench.lua bench/tserializebench_random.lua ' 1e6 2>&1 |  luajit -O bench/kbenchparse.lua
echo "4. Sample metalua dump"
bench/kbench.sh 'bench/bench.lua bench/tserializebench_metalua.lua ' 1e3 2>&1 |  luajit -O bench/kbenchparse.lua
