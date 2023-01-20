-- luacheck: globals import

require 'lua-nucleo'

local is_table = import 'lua-nucleo/type.lua' { 'is_table' }

local tproxymt = function(...)
  local nargs = select('#', ...)
  local args = { ... }

  local cache = setmetatable({ }, {
    __index = function(t, k)
      for i = 1, nargs do
        local v = args[i][k]
        if v ~= nil then
          t[k] = v
          return v
        end
      end
      return nil
    end;
  })

  return { __index = cache }
end

local tgetpatht = function(t, path)
  if not is_table(path) then
    return t[path] -- For convenience.
  end

  for i = 1, #path do
    t = t[path[i]]
    if t == nil then
      return nil
    end
  end

  return t
end

return
{
  tproxymt = tproxymt;
  tgetpatht = tgetpatht;
}
