--------------------------------------------------------------------------------
--- Scoped cat tree manager
-- @module lua-nucleo.scoped_cat_tree_manager
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert = assert

local table_insert, table_remove = table.insert, table.remove

--------------------------------------------------------------------------------

local make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

--------------------------------------------------------------------------------

-- TODO: Generalize
local make_scoped_cat_tree_manager
do
  local cat_key = unique_object()
  local concat_key = unique_object()

  local create_new_scope = function(self)
    local cat, concat = self:make_concatter_()
    return
    {
      [cat_key] = cat;
      [concat_key] = concat;
    }
  end

  -- Private method
  local get_current_scope = function(self)
    local parents = self.parents_
    return assert(parents[#parents])
  end

  -- Private method
  local push_new_scope = function(self)
    local scope = create_new_scope(self)
    table_insert(self.parents_, scope)
    return scope
  end

  -- Private method
  local pop_current_scope = function(self)
    return assert(table_remove(self.parents_))
  end

  local cat_current = function(self, str)
    return get_current_scope(self)[cat_key](str)
  end

  local concat_current = function(self, ...)
    return get_current_scope(self)[concat_key](...)
  end

  local maybe_concat_child = function(self, key, ...)
    local scope = assert(get_current_scope(self), "no children found")[key]
    if scope ~= nil then
      return scope[concat_key](...)
    end

    return nil
  end

  local concat_child = function(self, key, ...)
    local result = self:maybe_concat_child(key, ...)
    if not result then
      error("child " .. tostring(key) .. " not found")
    end
    return result
  end

  local push = function(self, key)

    local old_scope = get_current_scope(self)
    old_scope[key] = push_new_scope(self)
  end

  -- TODO: Use that key parameter somehow for validation
  local pop = function(self, key)

    pop_current_scope(self)
  end

  make_scoped_cat_tree_manager = function(custom_concatter_maker)
    custom_concatter_maker = custom_concatter_maker or make_concatter

    local result =
    {
      cat_current = cat_current;
      concat_current = concat_current;
      --
      concat_child = concat_child;
      maybe_concat_child = maybe_concat_child;
      --
      push = push;
      pop = pop;
      --
      make_concatter_ = custom_concatter_maker;
    }

    result.parents_ = { create_new_scope(result) };

    return result
  end
end

--------------------------------------------------------------------------------

return
{
  make_scoped_cat_tree_manager = make_scoped_cat_tree_manager;
}
