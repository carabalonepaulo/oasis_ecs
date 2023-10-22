local import = require 'lib.import'

local position, size, debug_rect, color = import('position', 'size', 'debug_rect', 'color')
    .from('src.raylib.components')

local tile = import('tile').from('src.world.components')

---

local MAP_SIZE = { 10, 10 }

local function create_map(world)
  for x = 1, MAP_SIZE[1] do
    for y = 1, MAP_SIZE[2] do
      world:spawn(
        debug_rect(),
        tile(),
        size { 32, 32 },
        position { x, y },
        color { 255, 10, 180, 255 }
      )
    end
  end
end

local function despawn_map(world)
  for entity in world:query(tile) do
    world:despawn(entity)
  end
end

--- @param app App
return function(app)
  app
      :add_system(create_map, 'once')
      :add_system(despawn_map, 'when', 'pressed_esc')
end
