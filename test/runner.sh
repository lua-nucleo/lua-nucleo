#!/bin/sh

# runner.sh -- script that starts tests
# This file is a part of lua-nucleo library
# Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

lua "test/test-lib/generate-test-list.lua"
lua "test/test.lua" "$@"
