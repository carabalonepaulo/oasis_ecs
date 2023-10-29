local BLACK = { 0, 0, 0, 0 }

local rl = require 'lib.raylib'
local begin_drawing = rl.BeginDrawing
local clear = rl.ClearBackground
local end_drawing = rl.EndDrawing

local steps = require 'lib.core.renderer.steps'
local ctx = require 'lib.core.renderer.context'
local iter = steps.iter

--- @param world World
local function draw(world)
  begin_drawing()
  clear(BLACK)

  for step in iter() do
    step(world, ctx)
  end

  end_drawing()
end


--- @param app App
return function(app)
  app
      :add_plugin('lib.core.renderer.sprites')
      :add_system(draw, 'always')
end
