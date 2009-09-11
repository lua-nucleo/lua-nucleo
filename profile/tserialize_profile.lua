require "profiler"

dofile("lua-nucleo/import.lua")

local gen_random_dataset = import 'test/lib/table.lua' { 'gen_random_dataset' }
local tserialize = import 'lua-nucleo/tserialize.lua' { 'tserialize' }

local datasets = {}
for i = 1, 20000 do
  datasets[i] = gen_random_dataset()
end

profiler:start()

for i = 1, #datasets do
  tserialize(datasets[i])
end

profiler:stop()
profiler:dump()