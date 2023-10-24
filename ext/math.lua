function math.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  end
  return value
end

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

function math.lerp(a, b, t)
  return a * (1.0 - t) + (b * t)
end
