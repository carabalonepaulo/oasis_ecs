--- @param self table
--- @param depth integer?
--- @return table
function table.clone(self, depth)
  depth = depth or 0
  local result = {}
  for k, v in pairs(self) do
    if type(v) == 'table' and depth > 0 then
      result[k] = table.clone(v, depth - 1)
    else
      result[k] = v
    end
  end
  return result
end
