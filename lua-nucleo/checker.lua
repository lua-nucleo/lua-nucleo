--------------------------------------------------------------------------------
--- Complex validation helper
-- @module lua-nucleo.checker
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert, tostring, select = assert, tostring, select
local table_concat = table.concat

-- TODO: Port to method_arguments()
local is_self,
      is_string
      = import 'lua-nucleo/type.lua'
      {
        'is_self',
        'is_string'
      }

local make_checker
do
  local ensure = function(self, msg, var, ...)
    assert(is_self(self))
    if not var then
      self:fail(
          (msg or "expectation failed") .. ": "
       .. (
            tostring(
                (select("#", ...) == 0)
                  and '(no additional error message)'
                   or (...)
              )
          )
        )
    end
    return var, ... -- Note input is passed through regardless of error.
  end

  local fail = function(self, msg)
    -- Not masking nil msg, as it is a likely error
    if msg ~= nil and not is_string(msg) then
      msg = tostring(msg)
    end

    assert(is_self(self))
    assert(is_string(msg))

    local errors = self.errors_
    errors[#errors + 1] = msg
  end

  local result = function(self, prefix, glue)
    assert(is_self(self))

    if self:good() then
      return true
    end

    return nil, self:msg(prefix, glue)
  end

  local good = function(self)
    assert(is_self(self))

    return (#self.errors_ == 0) and true or nil
  end

  local msg = function(self, prefix, glue)
    assert(is_self(self))

    return (#self.errors_ > 0)
       and ((prefix or "\n") .. table_concat(self.errors_, glue or "\n"))
        or ""
  end

  make_checker = function()

    return
    {
      ensure = ensure;
      fail = fail;

      result = result;
      good = good;
      msg = msg;

      --

      errors_ = {};
    }
  end
end

return
{
  make_checker = make_checker;
}
