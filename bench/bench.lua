local num_iter_default = 1000000

local filename = tostring(select(1, ...) or "")
local option = tostring(select(2, ...) or "")
local num_iter = tonumber(select(3, ...) or num_iter_default)

if filename == "" then
  io.stderr:write("Usage: lua bench.lua <filename.lua> <method> <num_iter>\n")
else
  local res, err = loadfile(filename)
  if not res then
    io.stderr:write("Failed to load file ", tostring(filename), " :\n", tostring(err), "\n")
  else
    local status, res = pcall(res)
    if not status then
      io.stderr:write("Failed to run file ", tostring(filename), " :\n", tostring(res), "\n")
    elseif type(res) ~= "table" then
      io.stderr:write(
          "Bad file ", tostring(filename),
          " result: handler_map table expected, got ", tostring(res), "\n"
        )
    else
      local handler = res[option]
      if not handler then
        print ([[
      Usage: lua bench.lua <filename.lua> <method> <num_iter>
      <method>: for file ]]..filename..[[ one of]])
      for name, method in pairs(res) do
        print("* "..name)
      end
        print([[
      <num_iter> : number of iterations, default ]]..num_iter_default..[[
      ]])
      else
        for i = 1, num_iter do
          handler()
        end
      end
    end
  end
end

io.stderr:flush()
io.stdout:flush()
