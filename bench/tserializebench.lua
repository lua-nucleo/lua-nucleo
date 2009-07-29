local table_concat = table.concat
local loadstring, assert = loadstring, assert
local pairs, type, tostring = pairs, type, tostring
local gen_random_dataset=loadfile("/data/Progz/lua/repo/lua-nucleo/lua/table.lua")()[ "gen_random_dataset"]
local tserialize=loadfile("/data/Progz/lua/repo/lua-nucleo/lua/tserialize.lua")() ["tserialize"]
dofile("/data/Progz/lua/repo/lua-nucleo/lua/serialize.lua")
local lua = "return {"..("true,false,134,"):rep(10240).."}"

local data = assert(loadstring(lua))()

--print("lua", #lua)
--print("saved", #saved)

local bench = {}



bench.tserialize = function()
  assert(tserialize(data))
end

bench.serialize = function()
  assert(serialize(data))
end



return bench
