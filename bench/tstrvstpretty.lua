-- tstrvstpretty.lua - benchmark, comparing tstr and tpretty
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local loadstring, assert = loadstring, assert
dofile('lua-nucleo/import.lua')
local tstr = import "lua-nucleo/tstr.lua" {"tstr"}
local tpretty = import "lua-nucleo/tpretty.lua" {"tpretty"}

local data = {
  {1,2,3},{4,5,6};
  {{{{1}}}};
}

local bench = {}

bench.tpretty = function()
  assert(tpretty(data,"  ", 80))
end

bench.tstr = function()
  assert(tstr(data))
end

return bench