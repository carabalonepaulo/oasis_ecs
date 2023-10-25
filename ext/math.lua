--- @param value number
--- @param min number
--- @param max number
--- @return number
function math.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  end
  return value
end

--- @param value number
--- @return number
function math.round(value)
  if value <= 2.49 then
    return math.floor(value)
  else
    return math.ceil(value)
  end
end

function math.randomize()
  math.randomseed(os.time())
  math.random()
  math.random()
  math.random()
end

--- @param a number initial value
--- @param b number final value
--- @param t number time
--- @return number
function math.lerp(a, b, t)
  return a * (1.0 - t) + (b * t)
end
