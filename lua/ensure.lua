local ensure_equals = function(msg, actual, expected)
  return 
      (actual ~= expected)
      and error(
          msg 
          .. ": actual `" .. tostring(actual)
          .. "' expected `" .. tostring(expected) 
          .. "'"
        )
      or actual
end

return
{
  ensure_equals = ensure_equals;
}
