#!/bin/sh

# strict-test.sh -- script that starts tests in strict (pre-release) mode
# This file is a part of lua-nucleo library
# Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

test/runner.sh --strict $@
