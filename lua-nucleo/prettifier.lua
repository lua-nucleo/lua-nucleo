--------------------------------------------------------------------------------
--- Creates prettifier object for pretty-printing lua tables
-- @module lua-nucleo.prettifier
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments'
      }

-- TODO: WTF?!?!?! Do not re-create everything each time!

local make_prettifier
do
  --- Prettifier factory.
  -- @tparam string indent An indent string to be used.
  -- @tparam table buffer Table to be used as a buffer.
  -- @tparam number cols Maximum allowed length of single line.
  -- @tparam[opt] table colors Optional color table. Specify if you want to
  -- define custom colors for various element of the output. Note: `reset_color`
  -- must always be specified. Available elements:
  -- <ul>
  --   <li>`curly_braces:` (string) string that will be inserted before curly
  --                                braces</li>
  --   <li>`key:` (string) string that will be inserted before table keys</li>
  --   <li>`boolean:` (string) string that will be inserted before booleans</li>
  --   <li>`string:` (string) string that will be inserted before strings</li>
  --   <li>`number:` (string) string that will be inserted before numbers</li>
  --   <li>`reset_color:` (string) string that will be inserted after the
  --                               entity which has a defined color</li>
  -- </ul>
  -- @treturn prettifier_instance Prettifier instance.
  make_prettifier = function(indent, buffer, cols, colors)
    arguments(
      'string', indent,
      'table', buffer,
      'number', cols
    )
    optional_arguments(
      'table', colors
    )

    local countlen = function(buf, start, finish)
      local count = 0
      for i = start, finish do
        count = count + #buf[i]
      end
      return count
    end

    --named constants...
    local SEPARATOR = 1
    local OPTIONAL_NEWLINE = 2
    local TERMINATING_SEPARATOR = 3
    local TABLE_END = 4
    local TABLE_BEGIN_LINE = 5
    local TABLE_BEGIN_MULTILINE = 6
    local MODE_LINE = 7
    local MODE_MULTILINE = 8

    local subst_multiline = { ';\n', '\n', ';\n', ' =\n' }
    local subst_line = { ', ', '', ' ', ' = ' }

    local level = 0
    local positions = { }
    local levels = { }
    local types = { }
    local father_table_pos = -1
    local prev_table_pos = -1
    local prev_table_len = 0

    --- Instance functions
    -- @section instance_function

    --- Increase current indent level.
    -- @function prettifier:increase_indent
    -- @return None
    local increase_indent = function(self)
      level = level + 1
    end

    --- Decrease current indent level.
    -- @function prettifier:decrease_indent
    -- @return None
    local decrease_indent = function(self)
      level = level - 1
    end

    local cat = function(self, item)
      self.buffer[#self.buffer + 1] = item
    end

    --- Add the separator.
    -- @function prettifier:separator
    -- @return None
    local separator = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[SEPARATOR]
      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, SEPARATOR
    end

    --- Add optional new line.
    -- @function prettifier:optional_nl
    -- @return None
    local optional_nl = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[OPTIONAL_NEWLINE]
      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, OPTIONAL_NEWLINE
    end

    --- Add terminating separator.
    -- @function prettifier:terminating_sep
    -- @return None
    local terminating_sep = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[TERMINATING_SEPARATOR]
      local num = #positions + 1
      positions[num], levels[num], types[num] =
        pos, level, TERMINATING_SEPARATOR
    end

    --- Table start hook.
    -- @function prettifier:table_start
    -- @return None
    local table_start = function(self)
      if -- Hack.
        not
        (
          positions[#positions] == #self.buffer and
          (
            types[#positions] == OPTIONAL_NEWLINE or
            types[#positions] == TERMINATING_SEPARATOR or
            types[#positions] == SEPARATOR
          )
        )
      then
        self:optional_nl()
      end
      self:increase_indent()

      self:before_open_curly_brace()
      local pos = #self.buffer + 1
      self.buffer[pos] = '{'
      self:after_open_curly_brace()

      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, TABLE_BEGIN_LINE
      if father_table_pos > 0 then
        types[father_table_pos] = TABLE_BEGIN_MULTILINE
      end
      father_table_pos = #types
      prev_table_pos = father_table_pos
      prev_table_len = 0
      self:optional_nl()
    end

    --- Table finish hook.
    -- @function prettifier:table_finish
    -- @return None
    local table_finish = function(self)
      self:decrease_indent()
      self:terminating_sep()

      self:before_closed_curly_brace()
      local pos = #self.buffer + 1
      self.buffer[pos] = '}'
      self:after_closed_curly_brace()

      if
        father_table_pos > 0
        and types[father_table_pos] == TABLE_BEGIN_LINE
      then
        prev_table_len = countlen(self.buffer, positions[father_table_pos], pos)
        local len = prev_table_len + level * #self.indent
        if len > self.cols then
          types[father_table_pos] = TABLE_BEGIN_MULTILINE
        end
      end
      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, TABLE_END
      father_table_pos = -1
    end

    --- Key start hook.
    -- @function prettifier:key_start
    -- @return None
    local key_start = function(self)
      prev_table_pos = -1

      if self.colors and self.colors.key then
        cat(self, self.colors.key)
      end

      -- compensate off-by-one in finish() where key replaced with
      -- separator or indentation
      cat(self, '')
    end

    --- Value start hook.
    -- @function prettifier:key_start
    -- @return None
    local value_start = function(self)
      local pos = #self.buffer + 1
      local len = 1
      if prev_table_pos == -1 then
        len = #(self.buffer[pos - 1])
      else
        if types[prev_table_pos] == TABLE_BEGIN_LINE then
          len = prev_table_len
        end
      end
      self.buffer[pos] = ' = '
      if len + level * #self.indent > self.cols then
        self:optional_nl()
      end
    end

    --- Key-value finish hook.
    -- @function prettifier:key_value_finish
    -- @return None
    local key_value_finish = function(self)
      -- Do nothing
    end

    local mt =
    {
      __index = function(t, k)
        local v = t.indent:rep(k)
        t[k] = v
        return v
      end
    }

    --- Finalize.
    -- @function prettifier:finished
    -- @return None
    local finished = function(self)
      local indent_cache = setmetatable(
          { indent = self.indent },
          mt
        )

      local mode = MODE_LINE
      for i = 1, #positions do
        local pos, pos_level, stype = positions[i], levels[i], types[i]
        if stype == TABLE_BEGIN_LINE then
          mode = MODE_LINE
          -- Hack.
          if i > 1 and pos_level > 1 then
            -- TODO: FIXME: do this only if there is enough space left
            --       on the line. Otherwise convert table to multiline.
            -- Bring short table back on the line with key.
            if
              types[i - 1] == OPTIONAL_NEWLINE and
              self.buffer[pos - 2] == ' = '
            then
              self.buffer[pos - 1] = ''
            end
          end

          self.buffer[pos] = '{ ' -- TODO: Should be done via subst_*

          -- TODO: Get rid of this.
          if
            types[i + 3] == TABLE_END and
            positions[i + 1] + 1 == positions[i + 2]
          then
            -- handle special case - empty table
            self.buffer[pos + 2] = '' -- replace TERMINATING_SEPARATOR
          end
        elseif stype == TABLE_BEGIN_MULTILINE then
          mode = MODE_MULTILINE
          -- TODO: FIXME: This should already be done by subst_*
          if pos > 2 then
            if self.buffer[pos - 2] == ' = ' then
              self.buffer[pos - 2] = ' ='
            end
          end
        elseif stype == TABLE_END then
          mode = MODE_MULTILINE
        elseif mode == MODE_MULTILINE then
          self.buffer[pos] = subst_multiline[stype] .. indent_cache[pos_level]
        end
      end
    end

    local prettifier =
    {
      indent = indent;
      buffer = buffer;
      cols = cols;
      colors = colors;
      increase_indent  = increase_indent;
      decrease_indent  = decrease_indent;
      separator        = separator;
      optional_nl      = optional_nl;
      terminating_sep  = terminating_sep;
      table_start      = table_start;
      table_finish     = table_finish;
      key_start        = key_start;
      value_start      = value_start;
      key_value_finish = key_value_finish;
      finished         = finished;
    }

    local make_colorizer = function(color_id)
      return function()
        if prettifier.colors and prettifier.colors[color_id] then
          cat(prettifier, prettifier.colors[color_id])
        end
      end
    end

    local make_color_resetter = function(color_id)
      return function()
        if prettifier.colors and prettifier.colors[color_id] then
          if not prettifier.colors.reset_color then
            error('the reset color must be defined')
          end
          cat(prettifier, prettifier.colors.reset_color)
        end
      end
    end

    -- Note: prettifier.key_start is already set

    --- Key finish hook.
    -- @function prettifier.key_finish
    -- @return None
    prettifier.key_finish = make_color_resetter('key')

    --- String start hook.
    -- @function prettifier.string_start
    -- @return None
    prettifier.string_start = make_colorizer('string')
    --- String finish hook.
    -- @function prettifier.string_finish
    -- @return None
    prettifier.string_finish = make_color_resetter('string')

    --- Number start hook.
    -- @function prettifier.number_start
    -- @return None
    prettifier.number_start = make_colorizer('number')
    --- Number finish hook.
    -- @function prettifier.number_finish
    -- @return None
    prettifier.number_finish = make_color_resetter('number')

    --- Boolean start hook.
    -- @function prettifier.boolean_start
    -- @return None
    prettifier.boolean_start = make_colorizer('boolean')
    --- Boolean finish hook.
    -- @function prettifier.boolean_finish
    -- @return None
    prettifier.boolean_finish = make_color_resetter('boolean')

    --- Before open curly brace hook.
    -- @function prettifier.before_open_curly_brace
    -- @return None
    prettifier.before_open_curly_brace = make_colorizer('curly_braces')
    --- Before closed curly brace hook.
    -- @function prettifier.before_closed_curly_brace
    -- @return None
    prettifier.before_closed_curly_brace = prettifier.before_open_curly_brace
    --- After open curly brace hook.
    -- @function prettifier.after_open_curly_brace
    -- @return None
    prettifier.after_open_curly_brace = make_color_resetter('curly_braces')
    --- After closed curly brace hook.
    -- @function prettifier.after_closed_curly_brace
    -- @return None
    prettifier.after_closed_curly_brace = prettifier.after_open_curly_brace

    return prettifier
  end
end

--- @export
return
{
  make_prettifier = make_prettifier;
}
