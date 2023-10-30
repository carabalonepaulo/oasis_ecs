require 'table.new'

local MAX_NUMBER = 2 ^ 52

--- @class Array<T>
local Array = setmetatable({}, {
  __call = function(self, ...)
    local args = { ... }
    local t = #args == 1 and args[1] or args
    return setmetatable((type(t) == 'table' and t or {}), { __index = self })
  end
})

--- @generic T
--- @param n integer
--- @return Array<T>
function Array.with_capacity(n)
  ---@diagnostic disable-next-line: undefined-field
  return table.new(n, 0)
end

--- @generic T
--- @return Array<T>
function Array.clone(self)
  local result = Array()
  for _, item in pairs(self) do
    result:insert(item)
  end
  return result
end

--- @param origin_index integer
--- @param final_index integer
function Array.swap(self, origin_index, final_index)
  local temp = self[origin_index]
  self[origin_index] = self[final_index]
  self[final_index] = temp
end

--- @generic T
--- @param item T
function Array.contains(self, item)
  for _, _item in pairs(self) do
    if _item == item then
      return true
    end
  end
  return false
end

--- @generic T
--- @param item T
function Array.find(self, item)
  for i, _item in pairs(self) do
    if _item == item then
      return i
    end
  end
  return -1
end

--- @generic T
--- @param callback fun(item: T, idx: integer)
function Array.each(self, callback)
  for i, item in pairs(self) do
    callback(item, i)
  end
end

function Array.where(self, callback)
  local result = Array()
  for i, item in pairs(self) do
    if callback(item, i) then
      table.insert(result, item)
    end
  end
  return result
end

function Array.map(self, callback)
  local result = Array()
  for i, item in pairs(self) do
    table.insert(result, callback(item, i))
  end
  return result
end

function Array.append(self, array)
  for _, v in pairs(array) do
    self:insert(v)
  end
end

function Array.flat(self, depth)
  local depth = depth or MAX_NUMBER
  local result = Array()
  local _type

  for _, value in pairs(self) do
    _type = type(value)
    if _type ~= 'table' then
      result:insert(value)
    elseif #value > 0 then
      error('not implemented yet')
      -- Array.from(value)
      --     :flat(depth - 1)
      --     :each(function(v)
      --       result:insert(v)
      --     end)
    end
  end

  return result
end

function Array.first(self)
  return self[1]
end

function Array.last(self)
  return self[#self]
end

function Array.slice(self, start, _end)
  local result = Array()
  local inc = start > _end and -1 or 1
  for i = start, _end, inc do
    result:insert(self[i])
  end
  return result
end

function Array.remove_slice(self, start, _end)
  return Array.flat {
    Array.slice(self, 1, start - 1),
    Array.slice(self, _end + 1, #self)
  }
end

-- callback: acumulador, valorAtual, index, array
function Array:reduce(callback, initial_value)
  initial_value = initial_value or self[1]
  for index, value in pairs(self) do
    initial_value = callback(initial_value, value, index, self)
  end
  return initial_value
end

function Array:length()
  return #self
end

function Array:swap_remove(idx)
  local len = #self
  self:swap(idx, len)
  self:remove(len)
end

function Array:swap_remove_by_value(value)
  local len = #self
  self:swap(self:find(value), len)
  self:remove(len)
end

Array.remove = table.remove
Array.insert = table.insert
Array.concat = table.concat

return Array
