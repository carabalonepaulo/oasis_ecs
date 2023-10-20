local Array = require 'lib.array'

return function(capacity)
  capacity = capacity or 1024

  local slots = Array.with_capacity(capacity)
  local highest_index = 0
  local available_indices = Array()
  local count = 0

  local function next()
    if #available_indices > 0 then
      return available_indices:remove()
    end
    highest_index = highest_index + 1
    return highest_index
  end

  return setmetatable({
    insert = function(_, value)
      assert(count < capacity)
      local key = next()
      slots[key] = value
      count = count + 1
      return key
    end,

    remove = function(_, key)
      assert(slots[key], 'Invalid key.')
      local value = slots[key]
      slots[key] = nil
      count = count - 1
      available_indices:insert(key)
      return value
    end,

    clear = function()
      slots = Array.with_capacity(capacity)
      highest_index = 0
      available_indices = Array()
      count = 0
    end,

    iter = function()
      local i = 0
      return function()
        i = i + 1
        while slots[i] == nil do
          i = i + 1
          if i > count then
            return nil
          end
        end
        return slots[i]
      end
    end,

    get = function(_, key)
      return slots[key]
    end,

    get_vacant_entry = function()
      local key = next()
      count = count + 1

      return {
        use = function(_, value)
          slots[key] = value
          return key
        end,

        discard = function()
          available_indices:insert(key)
          count = count - 1
        end
      }
    end
  }, {
    __index = function(_, key)
      assert(type(key) == 'number' and slots[key], 'Invalid key.')
      return slots[key]
    end,
    __len = function()
      return count
    end,
    __newindex = function(_, key, value)
      error("Can't assign values directly. Use 'insert' or 'get_vacant_entry' instead.")
    end
  })
end
