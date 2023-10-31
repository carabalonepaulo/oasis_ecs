local Array = require 'lib.collections.array'
local App = require 'lib.app'

local asset_server = require 'lib.core.asset_server'
local steps = require 'lib.core.renderer.steps'

local import = require 'lib.utils.import'
local texture, position, scale, color = import('texture', 'position', 'scale', 'color')
    .from('lib.core.components')

local sprites = Array.with_capacity(App.MAX_ENTITIES)
local last_sprites_count = 0
local meta = {}
local texture_cache = Array.with_capacity(App.MAX_ENTITIES)

--- @param world World
--- @param ctx Context
local function draw_sprites(world, ctx)
  for _, texture_handle, position, scale, color in world:query(texture, position, scale, color) do
    local cache = texture_cache[texture_handle]
    if cache then
      cache[3][1] = position[1]
      cache[3][2] = position[2]
      cache[3][3] = cache[2][3] * scale[1]
      cache[3][4] = cache[2][4] * scale[2]

      ctx.draw_texture(
        cache[1], -- texture
        cache[2], -- source rect
        cache[3], -- dest rect
        cache[4], -- origin
        0,        -- rotation
        color     -- color
      )
    end
  end
end

local function setup()
  steps.push(draw_sprites)
end

--- @param world World
local function on_texture_loaded(world, texture_handle)
  local texture = asset_server.get_handle_value(texture_handle)
  local tw, th = texture.width, texture.height

  -- TODO: create/use a cache component instead
  texture_cache[texture_handle] = {
    texture_handle,
    { 0, 0, tw, th },
    { 0, 0, 0,  0 },
    { 0, 0 },
  }
end

--- @param app App
return function(app)
  app
      :add_system(setup, 'once')
      :add_system(on_texture_loaded, 'when', 'asset_server.texture_loaded')
end
