--------------------------------------------------------------------------------
-- stack_with_factory.lua: stack manager creating new objects with factory
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local table_remove, table_insert = table.remove, table.insert

local make_stack_with_factory
do
  local head = function(self)
    return self.stack_[#self.stack_]
  end

  local push = function(self)
    table_insert(self.stack_, self.factory_())
  end

  local pop = function(self)
    return table_remove(self.stack_)
  end

  make_stack_with_factory = function(factory)

    return
    {
      head = head;
      push = push;
      pop = pop;
      --
      factory_ = factory;
      stack_ = { };
    }
  end
end

return
{
  make_stack_with_factory = make_stack_with_factory;
}
