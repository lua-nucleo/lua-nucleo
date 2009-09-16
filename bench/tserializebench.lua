-- tserializebench.lua - benchmark, comparing tserialize,
-- metalua serialize, luabins on moderate(~5 kBytes)
-- amount of simple data(no tables)
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local luabins = require("luabins")
local loadstring, assert = loadstring, assert
dofile('lua-nucleo/import.lua')
local gen_random_dataset = import "test/lib/table.lua"{ "gen_random_dataset"}
local tserialize = import "lua-nucleo/tserialize.lua" {"tserialize"}
dofile("bench/metalua_serialize.lua")

local lua = "return {" .. ("true,false,134,"):rep(1024) .. "}"
local data = assert(loadstring(lua))()

local bench = {}

bench.tserialize = function()
  assert(tserialize(data))
end

bench.metalua_serialize = function()
  assert(serialize(data))
end
if luabins then
  luabins_save = luabins.save
  bench.luabins_save = function()
    assert(luabins_save(data))
  end
end

return bench