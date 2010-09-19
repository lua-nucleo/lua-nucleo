-- ordered_named_cat_manager.lua: ordered named cat manager
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local tostring = tostring

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter'
      }

local torderedset,
      torderedset_insert
      = import 'lua-nucleo/table-utils.lua'
      {
        'torderedset',
        'torderedset_insert'
      }

--------------------------------------------------------------------------------

local make_ordered_named_cat_manager
do
  -- Private function
  local new_cat_concat = function(self, name)
    method_arguments(
        self,
        "string", name
      )

    local cat_concat = { make_concatter() }

    self.cats_[name] = cat_concat
    torderedset_insert(self.order_, name)

    return cat_concat
  end

  -- Private function
  local get_cat_concat = function(self, name)
    method_arguments(
        self,
        "string", name
      )

    return self.cats_[name] or new_cat_concat(self, name)
  end

  local name_exists = function(self, name)
    return not not self.cats_[name]
  end

  local named_set = function(self, name, text)
    text = tostring(text) or text
    method_arguments(
        self,
        "string", name,
        "string", text
      )

    new_cat_concat(self, name)
    self:named_cat(name) (text)
  end

  -- Returned value is valid until next call to manager. Do not store.
  local named_cat = function(self, name)
    return get_cat_concat(self, name)[1]
  end

  local named_concat = function(self, name, ...)
    return get_cat_concat(self, name)[2](...)
  end

  local concat_all = function(self, ...)
    method_arguments(self)

    local cat, concat = make_concatter()

    local order = self.order_
    for i = 1, #order do
      cat(self:named_concat(order[i]))
    end

    return concat(...)
  end

  make_ordered_named_cat_manager = function()

    return
    {
      named_set = named_set;
      named_cat = named_cat;
      named_concat = named_concat;
      concat_all = concat_all;
      name_exists = name_exists;
      --
      cats_ = { };
      order_ = torderedset({ });
    }
  end
end

--------------------------------------------------------------------------------

return
{
  make_ordered_named_cat_manager = make_ordered_named_cat_manager;
}
