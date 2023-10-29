local rl = require 'lib.raylib'
local settings = require 'settings'

--- @param world World
local function poll(world)
  if rl.WindowShouldClose() then
    world:emit('quit')
  end
end

--- @param world World
local function close_window(world)
  rl.CloseWindow()
  world.should_quit = true
end

--- @param app App
return function(app)
  rl.SetTraceLogLevel(7)

  local size = settings.window.size
  local title = settings.window.title
  rl.InitWindow(size[1], size[2], title)

  app
      :add_system(poll, 'always')
      :add_system(close_window, 'when', 'quit')
end
