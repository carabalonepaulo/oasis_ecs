local pp = require 'vendor.pp'
local ffi = require 'ffi'

do
  local file = io.open('./src/raylib/no_macro_raylib.h', 'r')
  if file then
    ffi.cdef(file:read('*a'))
    file:close()
  end
end

local rl = ffi.load('./bin/raylib.dll')
local keys = require 'src.raylib.keys'

local function create_window()
  rl.SetTraceLogLevel(7)
  rl.InitWindow(800, 600, 'ECS')
  rl.SetExitKey(keys.KEY_NULL)
end

--- @param world World
local function poll(world)
  if rl.WindowShouldClose() then
    world:emit('quit')
    return
  end

  rl.BeginDrawing()
  rl.ClearBackground({ 0, 0, 0 })

  do
    local rl_components = require('src.raylib.components')

    local position = rl_components.position
    local size = rl_components.size
    local debug_rect = rl_components.debug_rect
    local color = rl_components.color

    local query = world:query(debug_rect, size, position, color)

    for _, _, size, position, color in query do
      rl.DrawRectangle((position[1] - 1) * size[1], (position[2] - 1) * size[2],
        size[1], size[2], color)
    end
  end

  rl.EndDrawing()
end

--- @param world World
local function close_window(world)
  rl.CloseWindow()
  world.should_quit = true
end

--- @param world World
local function pressed_esc(world)
  if rl.IsKeyPressed(keys.KEY_ESCAPE) then
    world:emit('pressed_esc')
  end
end

--- @param app App
return function(app)
  app
      :add_system(create_window, 'once')
      :add_system(poll, 'always')
      :add_system(close_window, 'when', 'quit')
      :add_system(pressed_esc, 'always')
end
