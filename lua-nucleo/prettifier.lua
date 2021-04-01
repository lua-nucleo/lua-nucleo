--------------------------------------------------------------------------------
--- Creates prettifier object for pretty-printing lua tables
-- @module lua-nucleo.prettifier
-- This file is a part of lua-nucleo library
-- @copyright lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local assert_is_string,
      assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_string',
        'assert_is_table'
      }

-- TODO: WTF?!?!?! Do not re-create everything each time!

local make_prettifier
do
  make_prettifier = function(indent, buffer, cols, colors)
    if colors then
      assert_is_table(colors)
    end

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

    local subst_multiline = { ";\n", "\n", ";\n", " =\n" }
    local subst_line = { ", ", "", " ", " = " }

    local level = 0
    local positions = { }
    local levels = { }
    local types = { }
    local father_table_pos = -1
    local prev_table_pos = -1
    local prev_table_len = 0

    local increase_indent = function(_)
      level = level + 1
    end

    local decrease_indent = function(_)
      level = level - 1
    end

    local cat = function(self, item)
      self.buffer[#self.buffer + 1] = item
    end

    local separator = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[SEPARATOR]
      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, SEPARATOR
    end

    local optional_nl = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[OPTIONAL_NEWLINE]
      local num = #positions + 1
      positions[num], levels[num], types[num] = pos, level, OPTIONAL_NEWLINE
    end

    local terminating_sep = function(self)
      local pos = #self.buffer + 1
      self.buffer[pos] = subst_line[TERMINATING_SEPARATOR]
      local num = #positions + 1
      positions[num], levels[num], types[num] =
        pos, level, TERMINATING_SEPARATOR
    end

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
      self.buffer[pos] = "{"
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

    local table_finish = function(self)
      self:decrease_indent()
      self:terminating_sep()

      self:before_closed_curly_brace()
      local pos = #self.buffer + 1
      self.buffer[pos] = "}"
      self:after_closed_curly_brace()

      if colors then
        self.buffer[pos + 1] = colors.reset_color
      end
      if father_table_pos > 0 and
        types[father_table_pos] == TABLE_BEGIN_LINE then
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

    local key_start = function(self)
      prev_table_pos = -1

      -- compensate off-by-one in finish() where key replaced with
      -- separator or indentation
      self.buffer[#self.buffer + 1] = ""
    end

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
      self.buffer[pos] = " = "
      if len + level * #self.indent > self.cols then
        self:optional_nl()
      end
    end

    local key_value_finish = function(_)
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

    local finished = function(self)
      local indent_cache = setmetatable(
          { indent = self.indent },
          mt
        )

      local mode = MODE_LINE
      local pos, stype
      for i = 1, #positions do
        pos, level, stype = positions[i], levels[i], types[i]
        if stype == TABLE_BEGIN_LINE then
          mode = MODE_LINE
          -- Hack.
          if i > 1 and level > 1 then
            -- TODO: FIXME: do this only if there is enough space left
            --       on the line. Otherwise convert table to multiline.
            -- Bring short table back on the line with key.
            if
              types[i - 1] == OPTIONAL_NEWLINE and
              self.buffer[pos - 2] == " = "
            then
              self.buffer[pos - 1] = ""
            end
          end

          self.buffer[pos] = "{ " -- TODO: Should be done via subst_*

          -- TODO: Get rid of this.
          if
            types[i + 3] == TABLE_END and
            positions[i + 1] + 1 == positions[i + 2]
          then
            -- handle special case - empty table
            self.buffer[pos + 2] = "" -- replace TERMINATING_SEPARATOR
          end
        elseif stype == TABLE_BEGIN_MULTILINE then
          mode = MODE_MULTILINE
          -- TODO: FIXME: This should already be done by subst_*
          if pos > 2 then
            if self.buffer[pos - 2] == " = " then
              self.buffer[pos - 2] = " ="
            end
          end
        elseif stype == TABLE_END then
          mode = MODE_MULTILINE
        elseif mode == MODE_MULTILINE then
          self.buffer[pos] = subst_multiline[stype] .. indent_cache[level]
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
        if prettifier.colors and prettifier.colors[color_id] and prettifier.colors.reset_color then
          cat(prettifier, prettifier.colors.reset_color)
        end
      end
    end

    local reset_color = make_colorizer('reset_color')
    prettifier.string_start = make_colorizer('string')
    prettifier.string_finish = make_color_resetter('string')
    prettifier.number_start = make_colorizer('number')
    prettifier.number_finish = make_color_resetter('number')
    prettifier.boolean_start = make_colorizer('boolean')
    prettifier.boolean_finish = make_color_resetter('boolean')
    prettifier.nil_start = make_colorizer('nil_value')
    prettifier.nil_finish = make_color_resetter('nil_value')
    prettifier.key_finish = reset_color
    prettifier.before_open_bracket = make_colorizer('brackets')
    prettifier.before_closed_bracket = prettifier.before_open_bracket
    prettifier.after_open_bracket = make_color_resetter('brackets')
    prettifier.after_closed_bracket = prettifier.after_open_bracket
    prettifier.before_open_curly_brace = make_colorizer('curly_braces')
    prettifier.before_closed_curly_brace = prettifier.before_open_curly_brace
    prettifier.after_open_curly_brace = make_color_resetter('curly_braces')
    prettifier.after_closed_curly_brace = prettifier.after_open_curly_brace

    return prettifier
  end
end

return
{
  make_prettifier = make_prettifier;
}
