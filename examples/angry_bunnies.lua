local App = require 'lib.app'
local import = require 'lib.utils.import'
local create_component = App.create_component

local asset_server = require 'lib.core.asset_server'

local conditions = require('lib.core.conditions')
local component_exists = conditions.component_exists

local rl = require 'lib.raylib'
local keys = require 'lib.raylib.keys'

local controller_key_map = {
  [keys.KEY_A] = { 1, -1 },
  [keys.KEY_D] = { 1, 1 },
  [keys.KEY_W] = { 2, -1 },
  [keys.KEY_S] = { 2, 1 },
}

local is_key_down = rl.IsKeyDown
local is_key_pressed = rl.IsKeyPressed
local is_key_up = rl.IsKeyUp
local is_key_released = rl.IsKeyReleased
local get_frame_time = rl.GetFrameTime

local controller = create_component()
local speed = create_component()

local texture, position, scale, color = import('texture', 'position', 'scale', 'color')
    .from('lib.core.components')

--- @param world World
local function spawn(world)
  local wabbit_alpha = asset_server.load('wabbit_alpha.png')

  world:spawn(
    position { 10, 10, 0 },
    scale { 1, 1 },
    color { 255, 255, 255, 255 },
    texture(wabbit_alpha),
    speed(400),
    controller
  )
end

--- @param world World
local function move_sprite(world)
  local _, position, speed = world:query_first(position, speed, controller)

  local dir = { 0, 0 }
  local dt = get_frame_time()

  for k, v in pairs(controller_key_map) do
    if is_key_down(k) then
      dir[v[1]] = v[2]
    end
  end

  if dir[1] ~= 0 or dir[2] ~= 0 then
    position[1] = position[1] + speed * dt * dir[1]
    position[2] = position[2] + speed * dt * dir[2]
  end
end

--- @param world World
local function change_scale(world)
  local dir = 0

  if is_key_down(keys.KEY_N) then
    dir = dir + 1
  end

  if is_key_down(keys.KEY_M) then
    dir = dir - 1
  end

  if dir ~= 0 then
    local dt = get_frame_time()
    local _, scale, speed = world:query_first(scale, speed, controller)
    scale[1] = scale[1] + (speed / 5) * dt * dir
    scale[2] = scale[2] + (speed / 5) * dt * dir
  end
end

--- @param app App
return function(app)
  app
      :add_system(spawn, 'once')
      :add_system(change_scale, 'always')
      :add_system(move_sprite, 'always', component_exists(controller))
end
