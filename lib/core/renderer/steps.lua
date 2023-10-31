local Array = require 'lib.collections.array'
local steps = Array()

return {
  --- @param func fun(world: World, ctx: Context)
  push = function(func)
    steps:insert(func)
  end,

  --- @return fun(): any?
  iter = function()
    local i = 0
    return function()
      i = i + 1
      return rawget(steps, i)
    end
  end,
}
