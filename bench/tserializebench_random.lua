local loadstring, assert = loadstring, assert
dofile('lua-nucleo/import.lua')
local gen_random_dataset=import "test/lib/table.lua"{ "gen_random_dataset"}
local tserialize=import "lua-nucleo/tserialize.lua" {"tserialize"}
dofile("bench/metalua_serialize.lua")

local data = gen_random_dataset(1)

local bench = {}

bench.tserialize = function()
  assert(tserialize(data))
end

bench.metalua_serialize = function()
  assert(serialize(data))
end

return bench