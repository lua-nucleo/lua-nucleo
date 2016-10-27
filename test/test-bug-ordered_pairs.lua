-- Test based on real bug scenario -- https://github.com/lua-nucleo/lua-nucleo/issues/31

dofile('../lua-nucleo/import.lua')

local ordered_pairs
     = import '../lua-nucleo/tdeepequals.lua'
     {
       'ordered_pairs'
     }  

local test =
{
  [{ h = { } }] = '87',
  [{ b = { } }] = '66',
}
 
for k, v in ordered_pairs(test) do 
  print(k, v)
end