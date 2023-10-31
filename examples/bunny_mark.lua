local import = require 'lib.import'
local asset_server = require 'lib.core.asset_server'

local rl = require 'lib.raylib'
local mouse = require 'lib.raylib.mouse'

local rand = rl.GetRandomValue
local is_mouse_button_down = rl.IsMouseButtonDown
local get_frame_time = rl.GetFrameTime

local SCREEN_SIZE = { 800, 600 }
local MAX_BUNNIES = require('lib.app').MAX_ENTITIES

local create_component = require('lib.app').create_component

local bunny = create_component()
local speed = create_component 'number'
local position, scale, color, texture = import('position', 'scale', 'color', 'texture')
    .from('lib.core.components')

local bunny_texture = asset_server.load('wabbit_alpha.png')
local bunnies_count = 0

local function draw_fps()
  local steps = require 'lib.core.renderer.steps'
  steps.push(function(_, ctx)
    ctx.draw_fps(10, 10)
  end)
end

local function should_spawn()
  return is_mouse_button_down(mouse.BUTTON_LEFT) and bunnies_count < MAX_BUNNIES
end

--- @param world World
local function spawn(world)
  local mouse_pos = rl.GetMousePosition()
  for _ = 1, 1000 do
    if not should_spawn() then
      return
    end

    world:spawn(
      bunny,
      position { mouse_pos.x, mouse_pos.y },
      scale { 1, 1 },
      color { rand(50, 250), rand(50, 240), rand(50, 240), 255 },
      texture(bunny_texture),
      speed { rand(-250, 250), rand(-250, 250) }
    )
    bunnies_count = bunnies_count + 1
  end
end

--- @param world World
local function move(world)
  local dt = get_frame_time()
  for _, position, speed in world:query(position, speed) do
    position[1] = position[1] + speed[1] * dt
    position[2] = position[2] + speed[2] * dt

    for i = 1, 2 do
      if position[i] + 16 > SCREEN_SIZE[i] or position[i] + 16 < 0 then
        speed[i] = speed[i] * -1
      end
    end
  end
end

--- @param app App
return function(app)
  app
      :add_system(draw_fps, 'once')
      :add_system(spawn, 'always', should_spawn)
      :add_system(move, 'always')
end
