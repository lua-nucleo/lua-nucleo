--------------------------------------------------------------------------------
--- Path-based data walker
-- @module lua-nucleo.dsl.path_based_walker
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert, setmetatable
    = assert, setmetatable

--------------------------------------------------------------------------------

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

--------------------------------------------------------------------------------

local make_path_based_walker
do
  local SELF_KEY = unique_object()

  local proxy_handler = function(self, t)
    local handler = assert(self.handler_)
    self.handler_ = nil
    return handler(self.rules_, t)
  end

  local down_mt =
  {
    __index = function(t, k)
      local self = t[SELF_KEY]

      self.path_[#self.path_ + 1] = k

      assert(self.handler_ == nil)
      self.handler_ = self.rules_.down[self.path_]

      return self.handler_ and proxy_handler or nil -- not memoizing
    end;
  }

  local up_mt =
  {
    __index = function(t, k)
      local self = t[SELF_KEY]

      assert(self.handler_ == nil)
      self.handler_ = self.rules_.up[self.path_]

      assert(#self.path_ > 0, "bad implementation: up/down disbalance")
      self.path_[#self.path_] = nil

      return self.handler_ and proxy_handler or nil -- not memoizing
    end;
  }

  make_path_based_walker = function(rules)
    arguments(
        "table", rules
      )

    local self =
    {
      down = nil; -- Set below.
      up = nil; -- Set below.
      --
      rules_ = rules;
      path_ = { };
    }

    self.down = setmetatable({ [SELF_KEY] = self }, down_mt);
    self.up = setmetatable({ [SELF_KEY] = self }, up_mt);

    return self
  end
end

--------------------------------------------------------------------------------

return
{
  make_path_based_walker = make_path_based_walker;
}
