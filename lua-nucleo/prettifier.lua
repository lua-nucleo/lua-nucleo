-- prettyfier.lua -- creates special prettifier object for pretty-printing lua tables
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local create_prettifier;
do
  local countlen = function(buf, start, finish)
    local count = 0
    for i = start, finish do
      count = count + string.len(buf[i])
    end
    return count
  end

  create_prettifier = function(indent, buffer, cols)
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

    local p = {}
    local ind = indent
    local level = 0
    local septable = {}
    local prev_table_pos = -1
    local prev_table_len = 0

    function p:increase_indent()
      level = level + 1
    end

    function p:decrease_indent()
      level = level - 1
    end

    function p:separator()
      local pos = #buffer + 1
      buffer[pos] = subst[const.MODE_LINE][const.SEPARATOR]
      septable[#septable + 1] = {pos, level, const.SEPARATOR}
    end

    function p:optional_nl()
      local pos = #buffer + 1
      buffer[pos] = subst[const.MODE_LINE][const.OPTIONAL_NEWLINE]
      septable[#septable + 1] = {pos, level, const.OPTIONAL_NEWLINE}
    end

    function p:terminating_sep()
      local pos = #buffer + 1
      buffer[pos] = subst[const.MODE_LINE][const.TERMINATING_SEPARATOR]
      septable[#septable + 1] = {pos, level, const.TERMINATING_SEPARATOR}
    end

    function p:table_start()
      self:increase_indent()
      local pos = #buffer + 1
      buffer[pos] = "{"
      septable[#septable + 1] = {pos, level, const.TABLE_BEGIN_LINE}
      if prev_table_pos > 0 then
        septable[prev_table_pos][3] = const.TABLE_BEGIN_MULTILINE
      end
      prev_table_pos = #septable
      self:optional_nl()
    end

    function p:table_finish()
      self:decrease_indent()
      self:terminating_sep()
      local pos = #buffer + 1
      buffer[pos] = "}"
      if prev_table_pos > 0 and septable[prev_table_pos][3] == const.TABLE_BEGIN_LINE then
        local len = countlen(buffer,septable[prev_table_pos][1],pos)
        prev_table_len = len + level*string.len(indent)
        if prev_table_len > cols then
          septable[prev_table_pos][3] = const.TABLE_BEGIN_MULTILINE
          prev_table_len = 0
        end
      else
        prev_table_len = 0
      end
      septable[#septable + 1] = {pos, level, const.TABLE_END}
      prev_table_pos = -1
    end

    function p:key_start()
      prev_table_len = 0
    end

    function p:value_start()
      local pos = #buffer + 1
      buffer[pos] = " = "
      if prev_table_len + 5 > cols then
        self:optional_nl()
      end
    end

    function p:key_value_finish()
    end

    function p:finished()
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
          buffer[pos] = subst[mode][stype]..string.rep(indent, level)
        end
      end
    end
    return p
  end

end
return
{
  create_prettifier = create_prettifier;
}
