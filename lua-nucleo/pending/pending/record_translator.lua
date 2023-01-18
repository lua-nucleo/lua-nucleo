-- luacheck: globals import

require 'lua-nucleo'

local is_function,
      is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_function',
        'is_table'
      }

local identity,
      compose
      = import 'lua-nucleo/functional.lua'
      {
        'identity',
        'compose'
      }

local fill_curly_placeholders_numkeys
      = import 'lua-nucleo/pending/string.lua'
      {
        'fill_curly_placeholders_numkeys'
      }

local maybe_call
      = import 'lua-nucleo/pending/functional.lua'
      {
        'maybe_call'
      }

local function translate(raw, schema, result, ...)
  if is_function(schema) then
    return schema(raw, ...) -- Special case for handling array table content
  end

  for k, v in pairs(schema) do
    if is_function(k) then
      k = k(raw, ...)
    end

    if is_function(v) then
      v = v(raw, ...)
    elseif is_table(v) then
      v = translate(raw, v, { })
    end

    result[k] = v
  end

  return result
end

local translator = function(schema)
  return function(raw, ...)
    return translate(raw, schema, { }, ...)
  end
end

local captures
do
  captures = { }

  -- get Value
  captures.V = function(raw_key, mutator, ...)
    mutator = mutator or identity

    local args = { ... }

    return function(raw)
      return mutator(raw[raw_key], table.unpack(args))
    end
  end

  -- conditional
  captures.IF = function(v_capture, if_true, if_false, mutator, ...)
    mutator = mutator or identity

    local args = { ... }

    return function(raw)
      if v_capture(raw) then
        return mutator(maybe_call(if_true, raw), table.unpack(args))
      end
      return mutator(maybe_call(if_false, raw), table.unpack(args))
    end
  end

  -- multiconditional
  captures.MATCH = function(...)
    local n_args = select('#', ...)
    assert(n_args % 2 == 0)

    local args = { ... }

    return function(raw)
      for i = 1, n_args, 2 do
        local predicates, result = args[i], args[i + 1]
        local failed = false
        for j = 1, #predicates do
          if not predicates[j](raw) then
            failed = true
            break
          end
        end
        if not failed then
          return maybe_call(result, raw) -- No mutator support, sorry.
        end
      end
      error('no match')
    end
  end

  -- Mapper
  captures.M = function(raw_key, schema, ...)
    local args = { ... }

    return function(raw)
      local result = { }
      for i = 1, #raw[raw_key] do
        result[#result + 1] = translate(raw, schema, { }, i, table.unpack(args))
      end
      return result
    end
  end

  -- mapper Item
  captures.I = function(raw_key, mutator, ...)
    mutator = mutator or identity

    local args = { ... }

    return function(raw, i)
      return mutator(raw[raw_key][i], table.unpack(args))
    end
  end

  -- de-holed Array, nil if empty
  captures.A = function(...)
    local n_args = select('#', ...)
    local args = { ... }

    return function(raw)
      local result = { }

      for i = 1, n_args do
        local v = args[i](raw)
        if v ~= nil then
          result[#result + 1] = v
        end
      end

      return #result > 0 and result or nil
    end
  end

  -- String placeholders
  captures.S = function(template, mutator, ...)
    mutator = mutator or identity

    local args = { ... }

    return function(raw)
      return mutator(
        fill_curly_placeholders_numkeys(template, raw),
        table.unpack(args)
      )
    end
  end

  captures = setmetatable(captures, {
    __metatable = 'lua-nucleo.record_translator.captures';
    __index = function(_, k)
      error('unkonwn record_translator capture `' .. tostring(k) .. '`', 2)
    end;
    __newindex = function()
      error('attempted to write to a read-only table', 2)
    end
  })
end

local mutators
do
  mutators = { }

  mutators.equals = function(value)
    return function(v)
      return v == value
    end
  end

  mutators.to_percent_str = function(v)
    return v .. '%'
  end

  mutators.lookup = function(table, key)
    return function(v)
      return table[v][key]
    end
  end

  mutators = setmetatable(mutators, {
    __metatable = 'lua-nucleo.record_translator.mutators';
    __index = function(_, k)
      error('unkonwn record_translator mutator `' .. tostring(k) .. '`', 2)
    end;
    __newindex = function()
      error('attempted to write to a read-only table', 2)
    end
  })
end

return
{
  translator = translator;
  captures = captures;
  mutators = mutators;
}
