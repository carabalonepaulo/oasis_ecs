local create_component = require('lib.app').create_component
local a = create_component()

--- @param world World
local function spawn(world)
  for i = 1, 10 do
    world:spawn(a)
  end
end

--- @param world World
local function count(world)
  local count = 0
  for _ in world:query(a) do
    count = count + 1
  end
  print(count)
end

--- @param app App
return function(app)
  app
      :add_system(spawn, 'once')
      :add_system(count, 'always')
end
