-- prettyfier.lua -- creates special prettifier object for pretty-printing lua tables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local create_prettifier;
do
  local countlen = function(buf, start, finish)
    local count = 0
    for i = start, finish do
      count = count + #buf[i]
    end
    return count
  end

  --named constants...
  local SEPARATOR = 1;
  local OPTIONAL_NEWLINE =2;
  local TERMINATING_SEPARATOR = 3;
  local TABLE_END = 4;
  local TABLE_BEGIN_LINE = 5;
  local TABLE_BEGIN_MULTILINE = 6;
  local MODE_LINE = 7;
  local MODE_MULTILINE = 8;

  local subst_multiline = {";\n", "\n", ";\n", " =\n"}
  local subst_line = {", ", "", "", " = "}

  local level = 0
  local positions = {}
  local levels = {}
  local types = {}
  local father_table_pos = -1
  local prev_table_pos = -1
  local prev_table_len = 0

  local increase_indent = function(self)
    level = level + 1
  end

  local decrease_indent = function(self)
    level = level - 1
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
    positions[num], levels[num], types[num] = pos, level, TERMINATING_SEPARATOR
  end

  local table_start = function(self)
    self:increase_indent()
    local pos = #self.buffer + 1
    self.buffer[pos] = "{"
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
    local pos = #self.buffer + 1
    self.buffer[pos] = "}"
    if father_table_pos > 0 and types[father_table_pos] == TABLE_BEGIN_LINE then
      prev_table_len = countlen(self.buffer,positions[father_table_pos],pos)
      local len = prev_table_len + level*string.len(self.indent)
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
  end

  local value_start = function(self)
    local pos = #self.buffer + 1
    local len = 1
    if prev_table_pos == -1 then
      len = #(self.buffer[pos - 1]);
    else
      if types[prev_table_pos] == TABLE_BEGIN_LINE then
        len = prev_table_len
      end
    end
    self.buffer[pos] = " = "
    if len + level*string.len(self.indent) >  self.cols then
      self:optional_nl()
    end
  end

  local key_value_finish = function(self)
  end

  local finished = function(self)
    local mode = MODE_LINE
    for i = 1, #positions do
      local pos, level, stype = positions[i], levels[i], types[i]
      if stype == TABLE_BEGIN_LINE then
        mode = MODE_LINE;
      elseif stype == TABLE_BEGIN_MULTILINE then
        mode = MODE_MULTILINE;
      elseif stype == TABLE_END then
        mode = MODE_MULTILINE;
      elseif mode == MODE_MULTILINE then
        self.buffer[pos] = subst_multiline[stype]..string.rep(self.indent, level)
      end
    end
  end

  make_prettifier = function(indent, buffer, cols)
    return
    {
      indent = indent;
      buffer = buffer;
      cols = cols;
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
  end

end

return
{
  make_prettifier = make_prettifier;
}
