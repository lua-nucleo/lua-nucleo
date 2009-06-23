return setmetatable(
    {
      x = {};
      a = 1;
    },
    {
      __metatable = "Boo!";
    }
  )
