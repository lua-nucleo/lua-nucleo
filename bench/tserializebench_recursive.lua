-- tserializebench_recursive.lua - benchmark comparing tserialize
-- and metatables on simple, but recursive, table
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local loadstring, assert = loadstring, assert
dofile('lua-nucleo/import.lua')
local gen_random_dataset = import "test/lib/table.lua"{ "gen_random_dataset"}
local tserialize = import "lua-nucleo/tserialize.lua" {"tserialize"}
dofile("bench/metalua_serialize.lua")

local lua = [[
do
  local a = {}
  local b = {a,a}
  return b
end
]]
local data = assert(loadstring(lua))()

local bench = {}

bench.tserialize = function()
  assert(tserialize(data))
end

bench.metalua_serialize = function()
  assert(serialize(data))
end

return bench