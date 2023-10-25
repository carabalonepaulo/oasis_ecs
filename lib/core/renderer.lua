local App = require 'lib.app'
local Array = require 'lib.array'

local ffi = require 'ffi'

local asset_server = require 'lib.core.asset_server'

local rl = require 'lib.raylib'
-- local draw_texture = rl.DrawTexture
local draw_rect = rl.DrawRectangle
local draw_texture = rl.DrawTexturePro

local import = require 'lib.import'
local texture, position, scale, color = import('texture', 'position', 'scale', 'color')
    .from('lib.core.components')

local sprites = Array.with_capacity(App.MAX_ENTITIES)
local last_sprites_count = 0
local meta = {}

--- @param world World
local function draw_sprites(world)
  for entity in world:query(texture, position, scale, color) do
  end
  -- DrawTexturePro(Texture2D texture, Rectangle source, Rectangle dest,
  --     Vector2 origin, float rotation, Color tint)
  for _, texture_handle, position, scale, color in world:query(texture, position, scale, color) do
    if scale[1] ~= 1 or scale[2] ~= 1 then
      local texture = asset_server.get_handle_value(texture_handle)
      local tw, th = texture.width, texture.height

      draw_texture(
        texture,
        { 0, 0, tw, th },
        { position[1], position[2], tw * scale[1], th * scale[2] },
        { tw / 2, th / 2 },
        0,
        color
      )
    else
      rl.DrawTexture(asset_server.get_handle_value(texture_handle), position[1], position[2], color)
    end
  end
end

--- @param app App
return function(app)
  app:add_system(draw_sprites, 'always')
end
