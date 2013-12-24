--------------------------------------------------------------------------------
--- Table quicksort implementation
-- @module lua-nucleo.quicksort
-- Based on http://www.freelists.org/post/luajit/Lua-quicksort-implementation
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local math_floor = math.floor

local less_than
      = import "lua-nucleo/functional.lua"
      {
        "less_than"
      }

--- Sort table using quicksort method.
-- Sorts table inplace and returns it.
-- Sort is not stable beyond INSERTION_THRESOLD elements.
-- @param array table to be sorted
-- @param comp comparison function
-- @param from explicitly given first element index
-- @param to explicitly given last element index
-- @return sorted table
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

return
{
  quicksort = quicksort;
}
