#! /usr/bin/env bash

set -euox pipefail

options=( "--config" ".luacheckrc" )
exec /usr/bin/env luacheck "${options[@]}" .
