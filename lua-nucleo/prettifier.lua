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
  local const={
    SEPARATOR = 1;
    OPTIONAL_NEWLINE =2;
    TERMINATING_SEPARATOR = 3;
    TABLE_END = 4;
    TABLE_BEGIN_LINE = 5;
    TABLE_BEGIN_MULTILINE = 6;
    MODE_LINE = 7;
    MODE_MULTILINE = 8;
  }
  local subst =
  {
    [const.MODE_LINE] = {", ", "", "", " = "};--linear mode separators
    [const.MODE_MULTILINE] = {";\n", "\n", ";\n", " =\n"};--multiline mode separators
  }



  local level = 0
  local septable = {}
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
    self.buffer[pos] = subst[const.MODE_LINE][const.SEPARATOR]
    septable[#septable + 1] = {pos, level, const.SEPARATOR}
  end

  local optional_nl = function(self)
    local pos = #self.buffer + 1
    self.buffer[pos] = subst[const.MODE_LINE][const.OPTIONAL_NEWLINE]
    septable[#septable + 1] = {pos, level, const.OPTIONAL_NEWLINE}
  end

  local terminating_sep = function(self)
    local pos = #self.buffer + 1
    self.buffer[pos] = subst[const.MODE_LINE][const.TERMINATING_SEPARATOR]
    septable[#septable + 1] = {pos, level, const.TERMINATING_SEPARATOR}
  end

  local table_start = function(self)
    self:increase_indent()
    local pos = #self.buffer + 1
    self.buffer[pos] = "{"
    septable[#septable + 1] = {pos, level, const.TABLE_BEGIN_LINE}
    if prev_table_pos > 0 then
      septable[prev_table_pos][3] = const.TABLE_BEGIN_MULTILINE
    end
    prev_table_pos = #septable
    self:optional_nl()
  end

  local table_finish = function(self)
    self:decrease_indent()
    self:terminating_sep()
    local pos = #self.buffer + 1
    self.buffer[pos] = "}"
    if prev_table_pos > 0 and septable[prev_table_pos][3] == const.TABLE_BEGIN_LINE then
      local len = countlen(self.buffer,septable[prev_table_pos][1],pos)
      prev_table_len = len + level*string.len(self.indent)
      if prev_table_len > self.cols then
        septable[prev_table_pos][3] = const.TABLE_BEGIN_MULTILINE
        prev_table_len = 0
      end
    else
      prev_table_len = 0
    end
    septable[#septable + 1] = {pos, level, const.TABLE_END}
    prev_table_pos = -1
  end

  local key_start = function(self)
    prev_table_len = 0
  end

  local value_start = function(self)
    local pos = #self.buffer + 1
    self.buffer[pos] = " = "
    if prev_table_len + 5 > self.cols then
      self:optional_nl()
    end
  end

  local key_value_finish = function(self)
  end

  local finished = function(self)
    local mode = const.MODE_LINE
    for i = 1, #septable do
      local pos, level, stype = septable[i][1], septable[i][2], septable[i][3]
      if stype == const.TABLE_BEGIN_LINE then
        mode = const.MODE_LINE;
      elseif stype == const.TABLE_BEGIN_MULTILINE then
        mode = const.MODE_MULTILINE;
      elseif stype == const.TABLE_END then
        mode = const.MODE_MULTILINE;
      elseif mode == const.MODE_MULTILINE then
        self.buffer[pos] = subst[mode][stype]..string.rep(self.indent, level)
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
