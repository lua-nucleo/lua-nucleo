--------------------------------------------------------------------------------
--- Schema node dumper
-- @module lua-nucleo.dsl.dump_nodes
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

local walk_tagged_tree
      = import 'lua-nucleo/dsl/tagged-tree.lua'
      {
        'walk_tagged_tree'
      }

--------------------------------------------------------------------------------

-- TODO: Output should be more Lua-like!
-- #20
local dump_nodes = function(
    schema,
    out_filename,
    tag_field,
    name_field,
    with_indent,
    with_names
  )
  arguments(
      "table", schema,
      "string", out_filename,
      -- "string", tag_field,
      -- "string", name_field,
      "boolean", with_indent,
      "boolean", with_names
    )

  local out = (out_filename == "-")
    and io.stdout
     or assert(io.open(out_filename, "w"))

  local indent_cache = setmetatable(
      { },
      {
        __index = function(t, k)
          local v = ("  "):rep(with_indent and k or 0)
          t[k] = v
          return v
        end
      }
    )

  local walkers =
  {
    down = setmetatable(
        { },
        {
          __index = function(t, k)
            local v = function(walkers, data)
              out:write(indent_cache[walkers.indent_], data[tag_field])
              if with_names then
                out:write(" ", tostring(data[name_field]))
              end
              out:write("\n")
              walkers.indent_ = walkers.indent_ + 1
            end
            t[k] = v
            return v
          end
        }
      );
    up = setmetatable(
        { },
        {
          __index = function(t, k)
            local v = function(walkers, data)
              walkers.indent_ = walkers.indent_ - 1
            end
            t[k] = v
            return v
          end
        }
      );
    --
    indent_ = 0;
  }

  for i = 1, #schema do
    walk_tagged_tree(schema[i], walkers, tag_field)
  end

  if out ~= io.stdout then
    out:close()
  end
  out = nil
end

--------------------------------------------------------------------------------

return
{
  dump_nodes = dump_nodes;
}
