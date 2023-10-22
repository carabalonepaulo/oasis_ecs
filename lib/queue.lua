return function()
  local slots = {}
  local first = 0
  local last = -1
  local count = 0

  local function push_left(_, value)
    local temp = first - 1
    first = temp
    slots[first] = value
    count = count + 1
  end

  local function push_right(_, value)
    local temp = last + 1
    last = temp
    slots[last] = value
    count = count + 1
  end

  local function pop_left()
    local temp = first
    if temp > last then error('list is empty') end

    local value = slots[temp]
    slots[first] = nil
    first = first + 1
    count = count - 1
    return value
  end

  local function pop_right()
    local temp = last
    if first > temp then error('list is empty') end

    local value = slots[temp]
    slots[temp] = nil
    last = last - 1
    count = count - 1
    return value
  end

  local function iter()
    return function()
      if count > 0 then
        return pop_right()
      end
      return nil
    end
  end

  return {
    push_left = push_left,
    push_right = push_right,
    pop_left = pop_left,
    pop_right = pop_right,

    enqueue = push_right,
    dequeue = pop_left,
    count = function() return count end,
    iter = iter
  }
end
