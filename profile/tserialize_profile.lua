--------------------------------------------------------------------------------
-- tserialize_profile.lua: a profiler for tserialize module
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

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
