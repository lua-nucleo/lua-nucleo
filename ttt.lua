package.path = './?.lua;./?/init.lua;' .. package.path

require('lua-nucleo')

local tpretty,
      tpretty_ordered
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty',
        'tpretty_ordered'
      }

local ansi =
{
  reset_color =   '\x1b[0m';
  red =           '\x1b[30;31m';
  green =         '\x1b[30;32m';
  yellow =        '\x1b[30;33m';
  blue =          '\x1b[30;34m';
  magenta =       '\x1b[30;35m';
  cyan =          '\x1b[30;36m';
  gray =          '\x1b[30;90m';
  light_red =     '\x1b[30;91m';
  light_green =   '\x1b[30;92m';
  light_yellow =  '\x1b[30;93m';
  light_blue =    '\x1b[30;94m';
  light_magenta = '\x1b[30;95m';
  light_cyan =    '\x1b[30;96m';
  white =         '\x1b[30;97m';

  save_cursor_position = '\x1b[s';
  restore_cursor_position = '\x1b[u';
  clear_to_end_of_line = '\x1b[K';

  hide_cursor = '\x1b[?25l';
  show_cursor = '\x1b[?25h';

  report_cursor_position = '\x1b[6n';

  cursor_position = function(x, y)
    return '\x1b[' .. tostring(y) .. ';' .. tostring(x) .. 'H'
  end;

  cursor_up = function(lines)
    return '\x1b[' .. tostring(lines) .. 'A'
  end;

  cursor_down = function(lines)
    return '\x1b[' .. tostring(lines) .. 'B'
  end;

  cursor_left = function(chars)
    return '\x1b[' .. tostring(chars) .. 'D'
  end;

  cursor_right = function(chars)
    return '\x1b[' .. tostring(chars) .. 'C'
  end;
}

local obj = { a = 5, 1, 2, 3, "23423", { 1, 2, { bb = 7}}}

local a = {true, false, true, true ,true}
obj.b = true
obj[true] = 123
obj["string_key"] = "string_value"
obj[10000] = 20000
obj[8] = { 1, 2, nil, 3}
obj[{ a=1, b=2}] = { 1, 2, nil, 3}
obj[a] = { 1, false, true, 3}

local colors =
{
  boolean = ansi.light_cyan;
  key = ansi.cyan;
  curly_braces = ansi.white;
  brackets = ansi.white;
  string = ansi.green;
  number = ansi.light_blue;
  nil_value = ansi.magenta;
  reset_color = ansi.reset_color;
}

--declare('socket')
--declare('getfenv')
--require('mobdebug').start('192.168.2.95')

local colors =
{
  boolean = '<bool>';
  reset_color = '</>';
}

local ar = {[true] = false}
local obj =
{
  true;
  false;
  { [true] = 123 };
  { [{true, false}] = {false, true} };
  { [ar] = 'str' };
}

--print(tpretty(t, nil, nil, colors))
--print(tpretty({}, nil, nil, colors))
print(tpretty(obj, nil, nil, colors))
