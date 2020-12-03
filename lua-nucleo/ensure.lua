--------------------------------------------------------------------------------
--- Tools to ensure correct code behaviour
-- @module lua-nucleo.ensure
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local error, tostring, pcall, type, pairs, ipairs, select, next
    = error, tostring, pcall, type, pairs, ipairs, select, next

local math_min, math_max, math_abs = math.min, math.max, math.abs
local string_char = string.char

local tdeepequals,
      tstr,
      taccumulate,
      tnormalize
      = import 'lua-nucleo/table.lua'
      {
        'tdeepequals',
        'tstr',
        'taccumulate',
        'tnormalize'
      }

local tifindallpermutations
      = import 'lua-nucleo/table-utils.lua'
      {
        'tifindallpermutations'
      }

local assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number'
      }

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

-- TODO: Write tests for the function below
--       https://github.com/lua-nucleo/lua-nucleo/issues/13

--- @param msg
-- @param value
-- @param ...
local ensure = function(msg, value, ...)
  if not value then
    error(
            "ensure failed: " .. msg
            .. ((...) and (": " .. (tostring(...) or "?")) or ""),
            2
          )
  end
  return value, ...
end

-- TODO: Write tests for the function below
--       https://github.com/lua-nucleo/lua-nucleo/issues/13

--- @param msg
-- @param actual
-- @param expected
local ensure_equals = function(msg, actual, expected)
  return
      (actual ~= expected)
      and error(
          "ensure_equals failed: " .. msg
          .. ": actual `" .. tostring(actual)
          .. "', expected `" .. tostring(expected)
          .. "'",
          2
        )
      or actual -- NOTE: Should be last to allow false and nil values.
end

--- @param msg
-- @param value
-- @param expected_type
local ensure_is = function(msg, value, expected_type)
  local actual = type(value)
  return
      (actual ~= expected_type)
      and error(
          "ensure_is failed: " .. msg
          .. ": actual type `" .. tostring(actual)
          .. "', expected type `" .. tostring(expected_type)
          .. "'",
          2
        )
      or value -- NOTE: Should be last to allow false and nil values.
end

-- TODO: Write tests for the function below
--       https://github.com/lua-nucleo/lua-nucleo/issues/13

--- @param msg
-- @param actual
-- @param expected
local ensure_tequals = function(msg, actual, expected)
  if type(expected) ~= "table" then
    error(
        "ensure_tequals failed: " .. msg
        .. ": bad expected type, must be `table', got `"
        .. type(expected) .. "'",
        2
      )
  end

  if type(actual) ~= "table" then
    error(
        "ensure_tequals failed: " .. msg
        .. ": bad actual type, expected `table', got `"
        .. type(actual) .. "'",
        2
      )
  end

  -- TODO: Employ tdiff() (when it would be written)

  -- TODO: Use checker to get info on all bad keys!
  for k, expected_v in pairs(expected) do
    local actual_v = actual[k]
    if actual_v ~= expected_v then
      error(
          "ensure_tequals failed: " .. msg
          .. ": bad actual value at key `" .. tostring(k)
          .. "': got `" .. tostring(actual_v)
          .. "', expected `" .. tostring(expected_v)
          .. "'",
          2
        )
    end
  end

  for k, actual_v in pairs(actual) do
    if expected[k] == nil then
      error(
          "ensure_tequals failed: " .. msg
          .. ": unexpected actual value at key `" .. tostring(k)
          .. "': got `" .. tostring(actual_v)
          .. "', should be nil",
          2
        )
    end
  end

  return actual
end

--- @param msg
-- @param actual
-- @param expected
local ensure_tdeepequals = function(msg, actual, expected)
  -- Heavy! Use ensure_tequals if possible
  if not tdeepequals(actual, expected) then
    -- TODO: Bad! Improve error reporting (use tdiff)
    error(
        "ensure_tdeepequals failed: " .. msg .. ":"
        .. "\n  actual: " .. tstr(actual)
        .. "\nexpected: " .. tstr(expected),
        2
      )
  end
end

-- TODO: ?! Improve and generalize!
local strdiff_msg
do
  -- TODO: Generalize?
  local string_window = function(str, pos, window_radius)
    return str:sub(
        math_max(1, pos - window_radius),
        math_min(pos + window_radius, #str)
      )
  end

-- TODO: Uncomment and move to proper tests
--[=[
  assert(string_window("abCde", 3, 0) == [[C]])
  assert(string_window("abCde", 3, 1) == [[bCd]])
  assert(string_window("abCde", 3, 2) == [[abCde]])
  assert(string_window("abCde", 3, 3) == [[abCde]])
--]=]

  local nl_byte = ("\n"):byte()
  strdiff_msg = function(actual, expected, window_radius)
    window_radius = window_radius or 10

    local result = false

    --print(("%q"):format(expected))
    --print(("%q"):format(actual))

    if type(actual) ~= "string" or type(expected) ~= "string" then
      result = "(bad input)"
    else
      local nactual, nexpected = #actual, #expected
      local len = math_min(nactual, nexpected)

      local lineno, lineb = 1, 1
      for i = 1, len do
        local ab, eb = expected:byte(i), actual:byte(i)
        --print(string_char(eb), string_char(ab))
        if ab ~= eb then
          -- TODO: Do not want to have \n-s here. Too low level?!
          result = "different at byte " .. i .. " (line " .. lineno .. ", offset " .. lineb .. "):\n\n  expected   |"
                .. string_window(expected, i, window_radius)
                .. "|\nvs. actual   |"
                .. string_window(actual, i, window_radius)
                .. "|\n\n"
          break
        end
        if eb == nl_byte then
          lineno, lineb = lineno + 1, 1
        end
      end

      if nactual > nexpected then
        result = (result or "different: ") .. "actual has " .. (nactual - nexpected) .. " extra characters"
      elseif nactual < nexpected then
        result = (result or "different:" ) .. "expected has " .. (nexpected - nactual) .. " extra characters"
      end
    end

    return result or "(identical)"
  end
end

--------------------------------------------------------------------------------

--- @param msg
-- @param actual
-- @param expected
-- @param ...
local ensure_strequals = function(msg, actual, expected, ...)
  if actual == expected then
    return actual, expected, ...
  end

  error(
      "ensure_strequals: " .. msg .. ":\n"
      .. strdiff_msg(actual, expected)
      .. "\nactual:\n" .. tostring(actual)
      .. "\nexpected:\n" .. tostring(expected)
    )
end

--------------------------------------------------------------------------------

--- Checks if the `actual` string exists in the `expected` linear string array.
-- <br />
-- Returns all the arguments intact cutting the `msg` at beginning on success.
-- <br />
-- Raises the error on fail.
-- @tparam string msg Failing message that will be used in the error message if
--                    the check fails.
-- @tparam string actual A string to check.
-- @tparam string[] expected The linear array table of strings.
-- @tparam any[] ... Custom arguments.
-- @raise `ensure_strvariant failed error` if unable to find the `actual` string
--        in `expected`.
-- @treturn string `actual` intact.
-- @treturn string[] `expected` intact.
-- @treturn any[] ... The rest of the arguments intact.
-- @usage
-- local ensure_strvariant
--       = import 'lua-nucleo/ensure.lua'
--       {
--         'ensure_strvariant'
--       }
--
-- -- will pass without errors:
-- ensure_strvariant('find elem1', 'elem1', { 'elem0', 'elem1', 'elem2' })
--
-- -- will throw the error:
-- ensure_strvariant(
--     'find the_element_that_cannot_be_found',
--     'the_element_that_cannot_be_found',
--     { 'elem0', 'elem1', 'elem2' }
--   )
local ensure_strvariant = function(msg, actual, expected, ...)
  local confirmed = false

  if expected == nil then
    confirmed = actual == nil
  elseif type(expected) == 'string' then
    confirmed = actual == expected
  elseif type(expected) == 'table' then
    for i = 1, #expected do
      if actual == expected[i] then
        confirmed = true
        break
      end
    end
  end

  if confirmed then
    return actual, expected, ...
  end

  local expected_str
  if expected == nil then
    expected_str = 'nil'
  elseif type(expected) == 'string' then
    expected_str = expected
  elseif type(expected) == 'table' then
    expected_str = table.concat(expected, ' or ')
  else
    expected_str = 'unexpected type of the expected value: ' .. type(expected)
  end

  error(
      "ensure_strvariant failed: " .. msg .. ":\n"
      .. strdiff_msg(actual, expected)
      .. "\nactual:\n" .. tostring(actual)
      .. "\nexpected:\n" .. expected_str
    )
end

--- Checks if the `actual` string is constructed by the elements of
-- the `expected_elements_list` linear string array table. Expected that
-- elements are joined together with the `expected_sep` in between and not
-- necessarily have the same order as in the `expected_elements_list`. Also,
-- expected that the constructed list is prefixed by the `expected_prefix` and
-- terminated by the `expected_suffix`.
-- <br />
-- Returns all the arguments intact cutting the `msg` at beginning on success.
-- <br />
-- Raises the error on fail.
-- <br />
-- Best for simple long lists.
-- <br />
-- <br />
-- <b>How it works:</b> cut `expected_prefix` and `expected_suffix` from the
-- `actual` and break by `expected_sep`. Then find missing and excess elements
-- in two array traverses. Raises the error if found any.
-- @tparam string msg Failing message that will be used in the error message if
--         the check fails.
-- @tparam string actual A string to check.
-- @tparam string expected_prefix Expected prefix. Expected that the
--         `actual` must start with the `expected_prefix`.
-- @tparam string[] expected_elements_list Expected elements list. Expected that
--         `expected_elements_list` elements exist in the `actual`
--         whatever the original order from the `expected_elements_list`.
-- @tparam string expected_sep Expected separator character. Expected that this
--         separator is used to join list elements together.
-- @tparam string expected_suffix Expected suffix character. Expected that the
--         `actual` ends with the `expected_suffix`.
-- @tparam any[] ... Custom arguments.
-- @raise `ensure_strlist failed error` if the check fails.
-- @treturn string `actual` intact.
-- @treturn string `expected_prefix` intact.
-- @treturn string[] `expected_elements_list` intact.
-- @treturn string `expected_sep` intact.
-- @treturn string `expected_suffix` intact.
-- @treturn any[] ... The rest of the arguments intact.
-- @usage
-- local ensure_strlist
--       = import 'lua-nucleo/ensure.lua'
--       {
--         'ensure_strlist'
--       }
--
-- -- will pass without errors:
-- ensure_strlist(
--     'output check',
--     '(a,b,c,d,e)',
--     '(',
--     { 'a', 'b', 'c', 'd', 'e' },
--     ',',
--     ')'
--   )
--
-- -- will fail because the real separator is ', ':
-- -- ensure_strlist(
-- --     'output check',
-- --     '(a, b, c, d, e)',
-- --     '(',
-- --     { 'a', 'b', 'c', 'd', 'e' },
-- --     ',',
-- --     ')'
-- --   )
--
-- -- will pass without errors:
-- ensure_strlist(
--     'output check',
--     '1+b*c+m^2/2',
--     '',
--     { '1', 'b*c', 'm^2/2' },
--     '+',
--     ''
--   )
local ensure_strlist = function(
  msg,
  actual,
  expected_prefix,
  expected_elements_list,
  expected_sep,
  expected_suffix,
  ...
)
  if #expected_prefix > 0 then
    ensure_strequals(msg, actual:sub(1, #expected_prefix), expected_prefix)
  end
  if #expected_suffix > 0 then
    ensure_strequals(msg, actual:sub(-#expected_suffix), expected_suffix)
  end

  local actual_joined = actual:sub(1 + #expected_prefix, -1 - #expected_suffix)

  local missed_elements = { }
  local excess_elements = { }
  for _, elem in ipairs(expected_elements_list) do
    missed_elements[elem] = true
  end

  for elem in actual_joined:gmatch('([^' .. expected_sep .. ']+)') do
    if missed_elements[elem] then
      missed_elements[elem] = nil
    else
      excess_elements[#excess_elements + 1] = elem
    end
  end

  for elem, _ in pairs(missed_elements) do
    error(
      msg .. ': expected element is not found: ' .. tostring(elem)
    )
  end

  for _, elem in ipairs(excess_elements) do
    error(
      msg .. ': excess element is found: ' .. tostring(elem)
    )
  end

  return actual, expected_prefix, expected_elements_list, expected_sep,
         expected_suffix, ...
end

--- Checks if the `actual` string is constructed by the elements of
-- the `expected_elements_list` linear string array table. Expected that
-- elements are joined together with the `expected_sep` in between and not
-- necessarily have the same order as in the `expected_elements_list`. Also,
-- expected that the constructed list is prefixed by the `expected_prefix` and
-- terminated by the `expected_suffix`.
-- <br />
-- Returns all the arguments intact cutting the `msg` at beginning on success.
-- <br />
-- Raises the error on fail.
-- <br />
-- Best for complex short lists.
-- <br />
-- <br />
-- <b>How it works:</b> `tifindallpermutations` for the `expected_elements_list`
-- then build a table array containing all possible `actual`s using
-- `expected_prefix`, `expected_sep`, `expected_suffix` for each resulted
-- permutation. The `ensure_strvariant` is invoked as
-- `ensure_strvariant(msg, actual, expected_actuals)`
-- @tparam string msg Failing message that will be used in the error message if
--         the check fails.
-- @tparam string actual A string to check.
-- @tparam string expected_prefix Expected prefix. Expected that the
--         `actual` must start with the `expected_prefix`.
-- @tparam string[] expected_elements_list Expected elements list. Expected that
--         `expected_elements_list` elements exist in the `actual`
--         whatever the original order from the `expected_elements_list`.
-- @tparam string expected_sep Expected separator. Expected that this
--         separator is used to join list elements together.
-- @tparam string expected_suffix Expected suffix / footer. Expected that the
--         `actual` ends with the `expected_suffix`.
-- @tparam any[] ... Custom arguments.
-- @raise `ensure_strpermutations failed error` if the check fails.
-- @treturn string `actual` intact.
-- @treturn string `expected_prefix` intact.
-- @treturn string[] `expected_elements_list` intact.
-- @treturn string `expected_sep` intact.
-- @treturn string `expected_suffix` intact.
-- @treturn any[] ... The rest of the arguments intact.
-- @usage
-- local ensure_strpermutations
--       = import 'lua-nucleo/ensure.lua'
--       {
--         'ensure_strpermutations'
--       }
--
-- -- will pass without errors:
-- ensure_strlist(
--     'output check', "('a'+'b'+'c')", "('", { 'a', 'b', 'c' }) "'+'", "')"
--   )
-- ensure_strlist(
--     'output check', "('a'+'c'+'b')", "('", { 'a', 'b', 'c' }) "'+'", "')"
--   )
-- ensure_strlist(
--     'output check', "('c'+'a'+'b')", "('", { 'a', 'b', 'c' }) "'+'", "')"
--   )
-- ensure_strlist(
--     'output check', "('b'+'a'+'c')", "('", { 'a', 'b', 'c' }) "'+'", "')"
--   )
-- ensure_strlist(
--     'output check', "('b'+'c'+'a')", "('", { 'a', 'b', 'c' }) "'+'", "')"
-- )
--
-- -- wrong separator:
-- -- ensure_strlist(
-- --     'output check', "('a'+'b'+'c')", "('", { 'a', 'b', 'c' }) "' + '", "')"
-- --   )
--
-- -- wrong prefix:
-- -- ensure_strlist(
-- --     'output check', "['a'+'b'+'c')", "('", { 'a', 'b', 'c' }) "'+'", "')"
-- --   )
--
-- -- wrong suffix:
-- -- ensure_strlist(
-- --     'output check', "('a'+'b'+'c')", "('", { 'a', 'b', 'c' }) "'+'", "');"
-- --   )
--
-- -- missing elements:
-- -- ensure_strlist(
-- --     'output check', "('a'+'b')", "('", { 'a', 'b', 'c' }) "'+'", "');"
-- --   )
--
-- -- excess elements:
-- -- ensure_strlist(
-- --     'output check', "('a'+'b'+'c')", "('", { 'a', 'b' }) "'+'", "');"
-- --   )
local ensure_strpermutations = function(
  msg,
  actual,
  expected_prefix,
  expected_elements_list,
  expected_sep,
  expected_suffix,
  ...
)
  local expected_elements_list_permutations = { }
  tifindallpermutations(
    expected_elements_list, expected_elements_list_permutations
  )

  local expected_variants = { }
  for i = 1, #expected_elements_list_permutations do
    local p = expected_elements_list_permutations[i]
    local expected = expected_prefix
    for j = 1, #p do
      if j > 1 then
        expected = expected .. expected_sep
      end
      expected = expected .. tostring(p[j])
    end
    expected = expected .. expected_suffix
    expected_variants[#expected_variants + 1] = expected
  end

  return ensure_strvariant(msg, actual, expected_variants)
end

--------------------------------------------------------------------------------

--- @param msg
-- @param expected_message
-- @param res
-- @param actual_message
-- @param ...local ensure_error = function(msg, expected_message, res, actual_message, ...)
local ensure_error = function(msg, expected_message, res, actual_message, ...)
  if res ~= nil then
    error(
        "ensure_error failed: " .. msg
     .. ": failure expected, got non-nil result: `" .. tostring(res) .. "'",
        2
      )
  end

  -- TODO: Improve error reporting
  ensure_strequals(msg, actual_message, expected_message)
end

--------------------------------------------------------------------------------

--- @param msg
-- @param substring
-- @param res
-- @param err
local ensure_error_with_substring = function(msg, substring, res, err)
  if res ~= nil then
    error(
        "ensure_error_with_substring failed: " .. msg
     .. ": failure expected, got non-nil result: `" .. tostring(res) .. "'",
        2
      )
  end

  if
    substring ~= err and
    not err:find(substring, nil, true) and
    not err:find(substring)
  then
    error(
        "ensure_error_with_substring failed: " .. msg
        .. ": can't find expected substring `" .. tostring(substring)
        .. "' in error message:\n" .. err
      )
  end
end

--------------------------------------------------------------------------------

--- @param msg
-- @param fn
-- @param substring
local ensure_fails_with_substring = function(msg, fn, substring)
  local res, err = pcall(fn)

  if res ~= false then
    error("ensure_fails_with_substring failed: " .. msg .. ": call was expected to fail, but did not")
  end

  if type(err) ~= "string" then
    error("ensure_fails_with_substring failed: " .. msg .. ": call failed with non-string error")
  end

  if
    substring ~= err and
    not err:find(substring, nil, true) and
    not err:find(substring)
  then
    error(
        "ensure_fails_with_substring failed: " .. msg
        .. ": can't find expected substring `" .. tostring(substring)
        .. "' in error message:\n" .. err
      )
  end
end

--------------------------------------------------------------------------------

--- @param msg
-- @param str
-- @param substring
local ensure_has_substring = function(msg, str, substring)
  if type(str) ~= "string" then
    error(
        "ensure_has_substring failed: " .. msg .. ": value is not a string",
        2
      )
  end

  ensure(
     'ensure_has_substring failed: ' .. msg
      .. ": can't find expected substring `" .. tostring(substring)
      .. "' in string: `" .. str .. "'",
      (str == substring)
        or str:find(substring, nil, true)
        or str:find(substring)
    )

  return str
end

--------------------------------------------------------------------------------

--- We want 99.9% probability of success
-- Would not work for high-contrast weights. Use for tests only.
-- @param num_runs
-- @param weights
-- @param stats
-- @param max_acceptable_diff
local ensure_aposteriori_probability = function(num_runs, weights, stats, max_acceptable_diff)
  ensure_equals("total sum check", taccumulate(stats), num_runs)

  local apriori_probs = tnormalize(weights)
  local aposteriori_probs = tnormalize(stats)

  for k, apriori in pairs(apriori_probs) do
    local aposteriori = assert_is_number(aposteriori_probs[k])

    ensure("apriori must be positive", apriori > 0)
    ensure("aposteriori must be non-negative", aposteriori >= 0)

    -- TODO: Lame check. Improve it.
    local diff = math_abs(apriori - aposteriori) / apriori
    if diff > max_acceptable_diff then
      error(
          "inacceptable apriori-aposteriori difference key: `" .. tostring(k) .. "'"
          .. " num_runs: " .. num_runs
          .. " apriori: " .. apriori
          .. " aposteriori: " .. aposteriori
          .. " actual_diff: " .. diff
          .. " max_diff: " .. max_acceptable_diff
        )
    end

    aposteriori_probs[k] = nil -- To check there is no extra data below.
  end

  ensure_equals("no extra data", next(aposteriori_probs), nil)
end

--- @param msg
-- @param num
-- @param expected
-- @param ...
local ensure_returns = function(msg, num, expected, ...)
  local checker = make_checker()
  -- Explicit check to separate no-return-values from all-nils
  local actual_num = select("#", ...)
  if num ~= actual_num then
    checker:fail(
        "return value count mismatch: expected "
        .. num .. " actual " .. actual_num
      )
  end
  for i = 1, math_max(num, actual_num) do
    if not tdeepequals(expected[i], (select(i, ...))) then
      -- TODO: Enhance error reporting (especially for tables and long strings)
      checker:fail(
          "return value #" .. i .. " mismatch: "
          .. "actual `" .. tstr((select(i, ...)))
          .. "', expected `" .. tstr(expected[i])
          .. "'"
        )
    end
  end
  if not checker:good() then
    error(
        checker:msg(
            "return values check failed: " .. msg .. "\n -- ",
            "\n -- "
          ),
        2
      )
  end
  return ...
end

return
{
  ensure = ensure;
  ensure_equals = ensure_equals;
  ensure_is = ensure_is;
  ensure_tequals = ensure_tequals;
  ensure_tdeepequals = ensure_tdeepequals;
  ensure_strequals = ensure_strequals;
  ensure_strvariant = ensure_strvariant;
  ensure_strlist = ensure_strlist;
  ensure_strpermutations = ensure_strpermutations;
  ensure_error = ensure_error;
  ensure_error_with_substring = ensure_error_with_substring;
  ensure_fails_with_substring = ensure_fails_with_substring;
  ensure_has_substring = ensure_has_substring;
  ensure_aposteriori_probability = ensure_aposteriori_probability;
  ensure_returns = ensure_returns;
}
