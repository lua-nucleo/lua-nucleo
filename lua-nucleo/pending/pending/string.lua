-- luacheck: globals import

require 'lua-nucleo'

local fill_curly_placeholders
      = import 'lua-nucleo/string.lua'
      {
        'fill_curly_placeholders'
      }

local maybe_tonumber = function(v)
  return tonumber(v) or v
end

-- TODO: Optimize?
local fill_curly_placeholders_numkeys = function(template, dict)
  return fill_curly_placeholders(
    template,
    setmetatable({ }, {
      __index = function(_, k)
        return dict[k] or dict[tonumber(k)]
      end;
    })
  )
end

return
{
  maybe_tonumber = maybe_tonumber;
  fill_curly_placeholders_numkeys = fill_curly_placeholders_numkeys;
}
