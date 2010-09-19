-- scoped_cat_tree_manager.lua: scoped cat tree manager
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

-- TODO: Rename. This is not a proper tree.

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

  local create_new_scope = function()
    local cat, concat = make_concatter()
    return
    {
      [cat_key] = cat;
      [concat_key] = concat;
    }
  end

  local cat_current = function(self, str)
    return self.current_scope_[cat_key](str)
  end

  local concat_current = function(self, ...)
    return self.current_scope_[concat_key](...)
  end

  local maybe_concat_child = function(self, key, ...)
    local scope = assert(self.children_, "no children found")[key]
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
    local scope = create_new_scope()

    self.current_scope_[key] = scope
    table_insert(self.parents_, self.current_scope_)
    self.current_scope_ = scope
    self.children_ = nil
  end

  -- TODO: Use that key parameter somehow for validation
  local pop = function(self, key)
    -- Note that previous value is discarded
    self.children_ = self.current_scope_
    self.current_scope_ = assert(table_remove(self.parents_))
  end

  -- TODO: Optimizable?
  make_scoped_cat_tree_manager = function()

    return
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
      parents_ = { };
      current_scope_ = create_new_scope();
      children_ = nil;
    }
  end
end

--------------------------------------------------------------------------------

return
{
  make_scoped_cat_tree_manager = make_scoped_cat_tree_manager;
}
