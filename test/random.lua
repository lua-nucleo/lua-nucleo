-- algorithm.lua: tests for various common algorithms
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

math.randomseed(12345)

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local taccumulate,
      tnormalize,
      tclone
      = import 'lua-nucleo/table.lua'
      {
        'taccumulate',
        'tnormalize',
        'tclone'
      }

local ensure_probability_rough,
      ensure_probability_experiment,
      random_exports
      = import 'lua-nucleo/random.lua'
      {
        'ensure_probability_rough',
        'ensure_probability_experiment'
      }

--------------------------------------------------------------------------------

local test = make_suite("random", random_exports)

--------------------------------------------------------------------------------

test:test_for 'ensure_probability_rough' (function()
  local clock = os.clock
  local start = clock()

  local f_bubble_sort = function(t)
    for i = 2, #t do
      local b_switched = false
      for j = #t, i, -1 do
        if t[j][1] > t[j - 1][1] then
          t[j], t[j - 1] = t[j - 1], t[j]
          b_switched = true
        end
      end
      if b_switched == false then return t end
    end
    return t
  end

  local f_generator = function (t_probability_distribution, n_experiments)
    local t_probability_distribution_normalized =
          tnormalize(t_probability_distribution)
    local t_experiments = {}
    local t_formalize = {}
    local f_temp_probability = 0

    for k, v in pairs(t_probability_distribution) do
      t_experiments[k] = 0
      local f_cashed = f_temp_probability +
                       t_probability_distribution_normalized[k]
      t_formalize[#t_formalize + 1] = {f_cashed - f_temp_probability;
                                       ["name"] = k;
                                       ["probabilityWindow"] = {
                                         ["lowBound"] = f_temp_probability;
                                         ["upBound"] =  f_cashed;
                                       }
                                      }
      f_temp_probability = f_cashed
    end

    f_bubble_sort(t_formalize)

    for i = 1, n_experiments do
      local d_experiment_result = math.random()
      for i, v in ipairs(t_formalize) do
        if(d_experiment_result >=
           t_formalize[i]["probabilityWindow"]["lowBound"] and
           d_experiment_result < t_formalize[i]["probabilityWindow"]["upBound"]
          ) then
          t_experiments[t_formalize[i]["name"]] =
          t_experiments[t_formalize[i]["name"]] + 1
          break
        end
      end
    end

    return t_experiments
  end

  local f_generator_chances = function(n_number)
    local t_output = {}
    for i = 1, n_number do
      t_output[#t_output + 1] = math.random()
    end
    return t_output
  end

  local f_true_checks = function(n_cycles, n_length, t_weights, t_experiments,
                                 b_generate_weights, b_generate_experimants,
                                 n_num_experiments, t_generate_weights)
    b_generate_weights = b_generate_weights or false
    b_generate_experimants = b_generate_experimants or false
    n_num_experiments = n_num_experiments or 10^4
    if t_generate_weights == nil then t_generate_weights = t_weights end

    local n_true_checks_current = 0
    local t_curr_weights = t_weights
    local t_curr_experiments = t_experiments
    for i = 1, n_cycles do
      if b_generate_weights then
        t_curr_weights = f_generator_chances(n_length)
      end
      if b_generate_experimants then
        t_curr_experiments = f_generator(t_generate_weights, n_num_experiments)
      end
      if ensure_probability_rough(t_curr_weights, t_curr_experiments) then
        n_true_checks_current = n_true_checks_current + 1
      end
    end
    return n_true_checks_current
  end

  local n_set = 1000
  local n_cycles = 100
  local n_table = 2
  local t_weight = {}
  local t_experiments = {}
  local n_experiments = {}

  print("\nRandom \"false\" set")
  while n_table <= 100 do
    t_weight = f_generator_chances (n_table)
    t_experiments = f_generator (t_weight, n_set)
    n_experiments = f_true_checks(n_cycles, n_table, t_weight,
                                  t_experiments, true)
    print("Table size: " .. n_table .. " keys, false data, experiments: "
          .. n_set .. "\n" .. n_experiments .. " of " .. n_cycles ..
          " false positive.")
    if n_experiments == 100 then
      assert(nil, "Test failed!")
    end
    print("OK")
    if n_table < 10 then n_table = n_table + 2 else n_table = n_table + 30 end
  end

  print("\nRandom \"true\" set")
  n_table = 2
  while n_table <= 100 do
    t_weight = f_generator_chances (n_table)
    t_experiments = f_generator (t_weight, n_set)
    n_experiments = n_cycles -
                    f_true_checks(n_cycles,
                                  n_table,
                                  t_weight,
                                  t_experiments,
                                  false,
                                  true,
                                  n_set)
    print("Table size: " .. n_table .. " keys, correct data, experiments: "
          .. n_set .. "\n" .. n_experiments .. " of " .. n_cycles ..
          " false negative.")
    if n_experiments ~= 0 then
      assert(nil, "Test failed!")
    end
    print("OK")
    if n_table < 10 then n_table = n_table + 2 else n_table = n_table + 30 end
  end

  print(string.format("Time: %.3f s (fast test)", clock() - start))
end)

--------------------------------------------------------------------------------

-- TODO: Strict only, too long
test:test_for 'ensure_probability_experiment' (function()
  local clock = os.clock
  local start = clock()

  local f_bubble_sort = function(t)
    for i = 2, #t do
      local b_switched = false
      for j = #t, i, -1 do
        if t[j][1] > t[j - 1][1] then
          t[j], t[j - 1] = t[j - 1], t[j]
          b_switched = true
        end
      end
      if b_switched == false then return t end
    end
    return t
  end

  local f_generator = function (t_probability_distribution, n_experiments)
    local t_probability_distribution_normalized =
          tnormalize(t_probability_distribution)
    local t_experiments = {}
    local t_formalize = {}
    local f_temp_probability = 0

    for k, v in pairs(t_probability_distribution) do
      t_experiments[k] = 0
      local f_cashed = f_temp_probability +
                       t_probability_distribution_normalized[k]
      t_formalize[#t_formalize + 1] = {f_cashed - f_temp_probability;
                                       ["name"] = k;
                                       ["probabilityWindow"] = {
                                         ["lowBound"] = f_temp_probability;
                                         ["upBound"] =  f_cashed;
                                       }
                                      }
      f_temp_probability = f_cashed
    end

    f_bubble_sort(t_formalize)

    for i = 1, n_experiments do
      local d_experiment_result = math.random()
      for i, v in ipairs(t_formalize) do
        if(d_experiment_result >=
           t_formalize[i]["probabilityWindow"]["lowBound"]
           and d_experiment_result <
           t_formalize[i]["probabilityWindow"]["upBound"]
          ) then
          t_experiments[t_formalize[i]["name"]] =
          t_experiments[t_formalize[i]["name"]] + 1
          break
        end
      end
    end

    return t_experiments
  end

  local f_generator_chances = function(n_number)
    local t_output = {}
    for i = 1, n_number do
      t_output[#t_output + 1] = math.random()
    end
    return t_output
  end

  local f_generator_contrast_chances = function(n_number, n_pow, b_low_rare)
    local t_output = {}
    for i = 1, n_number do
      if b_low_rare then
        t_output[#t_output + 1] = math.pow(10, n_pow)
      else
        t_output[#t_output + 1] = 1
      end
    end
    if b_low_rare then
      t_output[math.random(n_number)] = 1
    else
      t_output[math.random(n_number)] = math.pow(10, n_pow)
    end
    return t_output
  end

  local t_probability_distribution_closure = f_generator_chances(20)
  local f_generator_defined = function(n_experiments)
    return f_generator(t_probability_distribution_closure, n_experiments)
  end

  print("\nRandom \"true\" set")
  local i = 2
  while i <= 100 do
    print("Table size: " .. i)
    t_probability_distribution_closure = f_generator_chances(i)
    local d_curr = ensure_probability_experiment(
                     t_probability_distribution_closure, f_generator_defined)
    if not d_curr then error("False negative!") else print("OK") end
    if i < 10 then i = i + 2 else i = i + 30 end
  end

  print("\nRandom \"false\" set")
  local i = 2
  while i <= 100 do
    print("Table size: " .. i)
    t_probability_distribution_closure = f_generator_chances(i)
    local t_probability_distribution_closure_false = f_generator_chances(i)
    local d_curr = ensure_probability_experiment(
                     t_probability_distribution_closure_false,
                     f_generator_defined)
    if d_curr then error("False positive!") else print("OK") end
    if i < 10 then i = i + 2 else i = i + 30 end
  end

  print("\nContrast \"true\" set")
  local i = 2
  while i <= 100 do
    print("\nTable size: " .. i)
    for j = 1, 3 do
      print("contrast: 1 and " .. i - 1 .. " of 10^" .. j)
      t_probability_distribution_closure =
        f_generator_contrast_chances (i, j, true)
      local d_curr = ensure_probability_experiment(
                       t_probability_distribution_closure, f_generator_defined)
      if not d_curr then error("False negative!") else print("OK") end

      print("contrast: " .. i - 1 .. " of 1 and 10^" .. j)
      t_probability_distribution_closure =
        f_generator_contrast_chances (i, j, false)
      d_curr = ensure_probability_experiment(
                 t_probability_distribution_closure, f_generator_defined)
      if not d_curr then error("False negative!") else print("OK") end
    end
    if i < 10 then i = i + 2 else i = i + 30 end
  end

  print("\nContrast \"false\" set")
  local i = 2
  while i <= 100 do
    print("\nTable size: " .. i)
    for j = 1, 2 do
      print("contrast: 1 and " .. i - 1 .. " of 10^" .. j ..
            ", added +" .. i .. " randomly.")
      t_probability_distribution_closure =
        f_generator_contrast_chances (i, j, true)
      local t_probability_distribution_closure_false =
              tclone(t_probability_distribution_closure)
      local n_cur = math.random(#t_probability_distribution_closure_false)
      t_probability_distribution_closure_false[n_cur] =
        t_probability_distribution_closure_false[n_cur] + i
      local d_curr = ensure_probability_experiment(
                      t_probability_distribution_closure_false,
                      f_generator_defined)
      if d_curr then error("False positive!") else print("OK") end

      print("contrast: " .. i - 1 .. " of 1 and 10^" .. j ..
            ", added +" .. i .. " randomly.")
      t_probability_distribution_closure =
        f_generator_contrast_chances (i, j, false)
      t_probability_distribution_closure_false =
        tclone(t_probability_distribution_closure)
      n_cur = math.random(#t_probability_distribution_closure_false)
      t_probability_distribution_closure_false[n_cur] =
        t_probability_distribution_closure_false[n_cur] + i
      d_curr = ensure_probability_experiment(
                t_probability_distribution_closure_false, f_generator_defined)
      if d_curr then error("False positive!") else print("OK") end
    end
    if i < 10 then i = i + 2 else i = i + 30 end
  end

  print(string.format("Time: %.3f s (slow test)", clock() - start))
end)

assert(test:run())
