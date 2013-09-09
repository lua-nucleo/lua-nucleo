--------------------------------------------------------------------------------
--- Tagged tree walk utilities
-- @module lua-nucleo.dsl.tagged-tree
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments,
      eat_true
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments',
        'eat_true'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

local empty_table,
      timap
      = import 'lua-nucleo/table-utils.lua'
      {
        'empty_table',
        'timap'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

--------------------------------------------------------------------------------

-- Down walker may return "break" to stop subtree traverse
-- Nodes with nil tag_field are not traversed
-- Nodes with unknown tag_fields are traversed
local walk_tagged_tree
do
  local function impl(tree, obj, down, up, tag_field, visited, key)
    assert(visited[tree] == nil, "recursion detected")
    visited[tree] = true

    local tag = tree[tag_field]
    if tag ~= nil then
      local skip = false

      local down_handler = down[tag]
      if down_handler then
        local res = down_handler(obj, tree, key)
        if res == "break" then
          skip = true
        else
          assert(res == nil, "unexpected down handler result")
        end
      end

      if not skip then
        for k, v in pairs(tree) do
          if is_table(v) then
            impl(v, obj, down, up, tag_field, visited, k)
          end
        end
      end

      if not skip then
        local up_handler = up[tag]
        if up_handler then
          up_handler(obj, tree, key)
        end
      end
    end

    visited[tree] = nil
  end

  walk_tagged_tree = function(tree, walkers, tag_field)
    arguments(
        "table", tree,
        "table", walkers
      )
    assert(tag_field ~= nil, "bad tag_field")
    assert(walkers.up or walkers.down, "need some handlers")

    impl(
        tree,
        walkers,
        walkers.down or empty_table,
        walkers.up or empty_table,
        tag_field,
        { },
        nil
      )
  end
end

--------------------------------------------------------------------------------

-- TODO: Deprecated, remove
-- #tmp3004
local create_simple_tagged_tree_walkers
do
  local obj_key = unique_object()
  local tag_handlers_key = unique_object()
  
  local wrap_handler = function(self, tag, obj, handler)
    return function(walkers, ...)
      return handler(obj, ...)
    end
  end

  local mt =
  {
    __index = function(t, tag)
      local obj = t[obj_key]
      local tag_handlers = t[tag_handlers_key]
      local handler = tag_handlers[tag]
      if not handler then
        error("unknown tag `" .. tostring(tag) .. "'", 2)
      end

      local v = wrap_handler(t, tag, obj, handler)
      t[tag] = v

      return v
    end;
  }

  create_simple_tagged_tree_walkers = function(obj, tag_handlers)
    arguments(
        "table", obj,
        "table", tag_handlers
      )

    return
    {
      up = setmetatable(
          {
            [obj_key] = obj;
            [tag_handlers_key] = tag_handlers;
          },
          mt
        );
    }
  end
end

--------------------------------------------------------------------------------

return
{
  walk_tagged_tree = walk_tagged_tree;
  create_simple_tagged_tree_walkers = create_simple_tagged_tree_walkers;
}
