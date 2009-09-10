package.cpath = "./profile/?.so;"..package.cpath
require "profiler"
dofile("lua-nucleo/import.lua")
local gen_random_dataset = import 'test/lib/table.lua' { 'gen_random_dataset' }
local tserialize = import 'lua-nucleo/tserialize.lua' { 'tserialize' }
profiler:start()
for i=1,2000 do
  tserialize(gen_random_dataset())
end
profiler:stop()
profiler:dump()