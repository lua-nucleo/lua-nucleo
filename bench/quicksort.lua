--------------------------------------------------------------------------------
-- quicksort.lua: quicksort implementation benchmark
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local table_sort = table.sort
local math_floor = math.floor

--------------------------------------------------------------------------------

local less_than
      = import "lua-nucleo/functional.lua"
      {
        "less_than"
      }

--------------------------------------------------------------------------------

--
-- original version using closures to pass array and comparison function
--
local quicksort_closure
do
  local INSERTION_THRESOLD = 16

  local insertion_sort = function(array, comp, from, to)
    for i = from + 1, to do
      local current_value = array[i]
      local hole_index = i
      while hole_index > from and comp(current_value, array[hole_index - 1]) do
        array[hole_index] = array[hole_index - 1]
        hole_index = hole_index - 1
      end
      array[hole_index] = current_value
    end
  end

  quicksort_closure = function(array, comp, from, to)
    comp = comp or less_than
    from = from or 1
    to = to or #array

    local move_median_first = function(a, b, c)
      if comp(array[a], array[b]) then
        if comp(array[b], array[c]) then
          array[a], array[b] = array[b], array[a]
        else
          array[a], array[c] = array[c], array[a]
        end
      elseif comp(array[a], array[c]) then
        return
      elseif comp(array[b], array[c]) then
        array[a], array[c] = array[c], array[a]
      else
        array[a], array[b] = array[b], array[a]
      end
    end

    local partition = function(from, to, pivot_value)
      while true do
        while comp(array[from], pivot_value) do
          from = from + 1
        end
        while comp(pivot_value, array[to]) do
          to = to - 1
        end
        if from >= to then
          return from
        end
        array[from], array[to] = array[to], array[from]
        from = from + 1
        to = to - 1
      end
    end

    local partition_pivot = function(from, to)
      local mid = math_floor((from + to) / 2)
      move_median_first(from, mid, to)
      return partition(from + 1, to, array[from])
    end

    local function quicksort_loop(from, to)
      while to - from > INSERTION_THRESOLD do
        local cut = partition_pivot(from, to)
        quicksort_loop(cut, to)
        array[from], array[from + 1] = array[from + 1], array[from]
        to = cut - 1
      end
    end

    quicksort_loop(from, to)
    insertion_sort(array, comp, from, to)

    return array
  end

end

--
-- explicitly passing array and comparison function to helpers
--
local quicksort
do
  local INSERTION_THRESOLD = 16

  local insertion_sort = function(array, comp, from, to)
    for i = from + 1, to do
      local current_value = array[i]
      local hole_index = i
      while hole_index > from and comp(current_value, array[hole_index - 1]) do
        array[hole_index] = array[hole_index - 1]
        hole_index = hole_index - 1
      end
      array[hole_index] = current_value
    end
  end

  local move_median_first = function(array, comp, a, b, c)
    if comp(array[a], array[b]) then
      if comp(array[b], array[c]) then
        array[a], array[b] = array[b], array[a]
      else
        array[a], array[c] = array[c], array[a]
      end
    elseif comp(array[a], array[c]) then
      return
    elseif comp(array[b], array[c]) then
      array[a], array[c] = array[c], array[a]
    else
      array[a], array[b] = array[b], array[a]
    end
  end

  local partition = function(array, comp, from, to, pivot_value)
    while true do
      while comp(array[from], pivot_value) do
        from = from + 1
      end
      while comp(pivot_value, array[to]) do
        to = to - 1
      end
      if from >= to then
        return from
      end
      array[from], array[to] = array[to], array[from]
      from = from + 1
      to = to - 1
    end
  end

  local partition_pivot = function(array, comp, from, to)
    local mid = math_floor((from + to) / 2)
    move_median_first(array, comp, from, mid, to)
    return partition(array, comp, from + 1, to, array[from])
  end

  local function quicksort_loop(array, comp, from, to)
    while to - from > INSERTION_THRESOLD do
      local cut = partition_pivot(array, comp, from, to)
      quicksort_loop(array, comp, cut, to)
      array[from], array[from + 1] = array[from + 1], array[from]
      to = cut - 1
    end
  end

  quicksort = function(array, comp, from, to)
    comp = comp or less_than
    from = from or 1
    to = to or #array

    quicksort_loop(array, comp, from, to)
    insertion_sort(array, comp, from, to)

    return array
  end

end

--------------------------------------------------------------------------------

local NELEM = tonumber(os.getenv("NELEM") or "16")

math.randomseed(os.time())

--------------------------------------------------------------------------------

local create_table_rev = function(n)
  local r = { }
  for i = 1, n do
    r[i] = n - i
  end
  return r
end

local create_table_rnd = function(n)
  local r = { }
  for i = 1, n do
    r[i] = math.random(n)
  end
  return r
end

--------------------------------------------------------------------------------

local bench = { }

-- NB: to account time spent in table creation
bench.create_table_rev = function()
  return create_table_rev(NELEM)
end

-- NB: to account time spent in table creation
bench.create_table_rnd = function()
  return create_table_rnd(NELEM)
end

bench.sort_rev = function()
  local t = create_table_rev(NELEM)
  table_sort(t)
end

bench.sort_rnd = function()
  local t = create_table_rnd(NELEM)
  table_sort(t)
end

bench.qsort_rev_closure = function()
  local t = create_table_rev(NELEM)
  quicksort_closure(t)
end

bench.qsort_rnd_closure = function()
  local t = create_table_rnd(NELEM)
  quicksort_closure(t)
end

bench.qsort_rev = function()
  local t = create_table_rev(NELEM)
  quicksort(t)
end

bench.qsort_rnd = function()
  local t = create_table_rnd(NELEM)
  quicksort(t)
end

return bench
