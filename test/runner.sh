#!/bin/sh

# runner.sh -- script that starts tests
# This file is a part of lua-nucleo library
# Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

lua "`dirname $0`/test-lib/generate-test-list.lua"
lua "`dirname $0`/test.lua" $@
