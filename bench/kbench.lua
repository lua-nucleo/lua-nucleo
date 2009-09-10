-- kbench.lua -- the part of benchmarking utilities collection
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--[[ Shell script to call all benchmarks at once:
#! /bin/sh

KBENCH_SCRIPT=kbench.lua
KBENCH_INTERPRETERS=( 'lua' 'luajit -O' )
KBENCH_METHODS=( $(${KBENCH_INTERPRETERS[0]} $KBENCH_SCRIPT | grep -e '^\* \(.*\)$' | awk '{ print $2 }') )
KBENCH_NUM_ITER=10000000 # 10M

for interpreter in "${KBENCH_INTERPRETERS[@]}"; do
  for method in "${KBENCH_METHODS[@]}"; do
    command="time $interpreter $KBENCH_SCRIPT $method $KBENCH_NUM_ITER"
    echo \$ $command
    $command
    echo
  done
done
--]]

--[[ Output:

$ time lua kbench.lua noop 10000000
        1.47 real         1.45 user         0.00 sys

$ time lua kbench.lua c 10000000
        4.56 real         4.45 user         0.02 sys

$ time lua kbench.lua generated 10000000
        8.31 real         8.05 user         0.04 sys

$ time lua kbench.lua recursive 10000000
       21.07 real        20.63 user         0.10 sys

$ time lua kbench.lua unpack 10000000
       48.15 real        46.84 user         0.27 sys

$ time luajit -O kbench.lua noop 10000000
        0.18 real         0.18 user         0.00 sys

$ time luajit -O kbench.lua c 10000000
        2.74 real         2.69 user         0.01 sys

$ time luajit -O kbench.lua generated 10000000
        2.12 real         2.07 user         0.01 sys

$ time luajit -O kbench.lua recursive 10000000
        6.58 real         6.46 user         0.03 sys

$ time luajit -O kbench.lua unpack 10000000
       30.55 real        29.81 user         0.16 sys

--]]

--[[ C module 'misc.so' should export following function as 'extract_keys'
 static int Lextract_keys(lua_State * L) {
     int nargs = lua_gettop(L);
     int i = 2;

     luaL_checktype(L, 1, LUA_TTABLE);
     for (i = 2; i <= nargs; ++i) {
       lua_pushvalue(L, i);
       lua_gettable(L, 1);
     }

     return nargs - 1;
   }
--]]
local res, m = pcall(require, "misc")

local select, unpack, assert, loadstring, rawset = select, unpack, assert, loadstring, rawset
local table_concat = table.concat

local tvalues, tvalues_nocache
do
  local generate_extractor = function(n)
    assert(type(n) == "number")
    local a, r = {}, {}
    for i = 1, n do
      a[i], r[i] = 'a'..i, 't[a'..i..']'
    end
    return assert(
        loadstring(
            [[return function(t,]]..table_concat(a, ",")..[[)return ]]..table_concat(r, ",").."end",
            "extract_keys_"..n
          )
      )()
  end

  local extractors_mt =
  {
    __index = function(t, k)
      local v = generate_extractor(k)
      rawset(t, k, v)
      return v
    end
  }

  local extractors = setmetatable(
      {
        [0] = function(t) end;
        [1] = function(t, a1) return t[a1] end;
        [2] = function(t, a1, a2) return t[a1], t[a2] end;
        [3] = function(t, a1, a2, a3) return t[a1], t[a2], t[a3] end;
        [4] = function(t, a1, a2, a3, a4) return t[a1], t[a2], t[a3], t[a4] end;
        [5] = function(t, a1, a2, a3, a4, a5) return t[a1], t[a2], t[a3], t[a4], t[a5] end;
      },
      extractors_mt
    )

  tvalues = function(t, ...)
    return extractors[select("#", ...)](t, ...)
  end

  tvalues_nocache = function(t, ...)
    return generate_extractor(select("#", ...))(t, ...)
  end
end

local extract_keys_unpack = function(t, ...)
  local results = {}
  local nargs = select("#", ...)
  for i = 1, nargs do
    results[i] = t[select(i, ...)]
  end
  return unpack(results, 1, nargs)
end

local extract_keys_recursive; extract_keys_recursive = function (tab, ...)
  local key = (...)
  if key ~= nil then
    return tab[key], extract_keys_recursive(tab, select(2,...))
  end
end

local extract_keys_recursive_2; extract_keys_recursive_2 = function(tab, ...)
  if select("#", ...) > 0 then
    return tab[...], map(tab, select(2,...))
  end
end

local do_nothing = function() end

local extract_keys_map =
{
  generated = tvalues;
  generated_nocache = tvalues_nocache;
  unpack = extract_keys_unpack;
  recursive = extract_keys_recursive;
  recursive_2 = extract_keys_recursive_2;
  noop = do_nothing;
}

if m and m.extract_keys then
  extract_keys_map.c = m.extract_keys;
else
  print("warning: plain C version is not found")
end

local num_iter_default = 1000000
local option, num_iter = tostring(select(1, ...) or ""), tonumber(select(2, ...) or num_iter_default)

local handler = extract_keys_map[option]
if not handler then
  print ([[
Usage: lua kbench.lua <method> <num_iter>
<method>: one of]])
for name, method in pairs(extract_keys_map) do
  print("* "..name)
end
  print([[
<num_iter> : number of iterations, default ]]..num_iter_default..[[
]])
else
  local data = { }
  do
    local base = ("a"):byte()
    local dist = ("z"):byte() - base

    for i = 0, dist do
      data[string.char(base + i)] = i
    end
  end
  for i = 1, num_iter do
    handler(data, "a", "xxx", "z", "m", "yyy")
  end
end
