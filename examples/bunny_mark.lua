local import = require 'lib.import'
local asset_server = require 'lib.core.asset_server'

local rl = require 'lib.raylib'
local rand = rl.GetRandomValue
local keys = require 'lib.raylib.keys'
local mouse = require 'lib.raylib.mouse'

local create_component = require('lib.app').create_component

local SCREEN_SIZE = { 800, 600 }
local MAX_BUNNIES = require('lib.app').MAX_ENTITIES
local WHITE = { 255, 255, 255, 255 }

local bunny_texture
local bunnies_count = 0

local bunny = create_component()
local position, scale, color, texture = import('position', 'scale', 'color', 'texture')
    .from('lib.core.components')
local speed = create_component()

local is_mouse_button_down = rl.IsMouseButtonDown
local draw_texture = rl.DrawTexture
local draw_text = rl.DrawText
local draw_fps = rl.DrawFPS
local begin_drawing = rl.BeginDrawing
local end_drawing = rl.EndDrawing
local clear = rl.ClearBackground
local window_should_close = rl.WindowShouldClose

local function setup()
  rl.SetTraceLogLevel(7)
  rl.InitWindow(800, 600, 'ECS')
  rl.SetExitKey(keys.KEY_NULL)
  rl.SetTargetFPS(60)

  local id = asset_server.load('wabbit_alpha.png')
  bunny_texture = asset_server.get_handle_value(id)
end

local function should_spawn()
  return is_mouse_button_down(mouse.BUTTON_LEFT) and bunnies_count < MAX_BUNNIES
end

--- @param world World
local function spawn_bunnies(world)
  for i = 1, 1000 do
    if not should_spawn() then
      return
    end
    local mouse_pos = rl.GetMousePosition()
    local pos       = position { mouse_pos.x, mouse_pos.y }
    local speed     = speed { rand(-250, 250) / 60, rand(-250, 250) / 60 }
    local color     = color { rand(50, 250), rand(50, 240), rand(50, 240), 255 }

    local scale     = { 1, 1 }
    local texture   = texture(bunny_texture)

    world:spawn(bunny, pos, speed, color, scale, texture)
    bunnies_count = bunnies_count + 1
  end
end

--- @param world World
local function move(world)
  for _, position, speed in world:query(position, speed) do
    position[1] = position[1] + speed[1]
    position[2] = position[2] + speed[2]

    for i = 1, 2 do
      if position[i] + 16 > SCREEN_SIZE[i] or position[i] + 16 < 0 then
        speed[i] = speed[i] * -1
      end
    end
  end
end

--- @param world World
local function draw(world)
  begin_drawing()

  clear { 0, 0, 0, 0 }
  for _, position, color in world:query(position, color, bunny) do
    draw_texture(bunny_texture, position[1], position[2], color)
  end

  draw_fps(10, 10)
  draw_text(tostring(bunnies_count), 10, 40, 20, WHITE)
  end_drawing()
end

--- @param world World
local function poll(world)
  if window_should_close() then
    world.should_quit = true
    rl.CloseWindow()
  end
end

--- @param app App
return function(app)
  app
      :add_system(setup, 'once')
      :add_system(spawn_bunnies, 'always', should_spawn)
      :add_system(move, 'always')
      :add_system(draw, 'always')
      :add_system(poll, 'always')
end
