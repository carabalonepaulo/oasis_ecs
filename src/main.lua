local App = require 'lib.app'
local component = App.create_component

---

local MAP_SIZE = { 10, 10 }

local position = component()
local tile = component()

local function create_map(world)
  for x = 1, MAP_SIZE[1] do
    for y = 1, MAP_SIZE[2] do
      world:spawn(
        tile(),
        position { x = 0, y = 0, z = 0 }
      )
    end
  end
end

---

App()
-- :add_plugin('src.raylib')
    :add_system(create_map, 'once')
    :run()
