local rl = require 'lib.raylib'
local draw_rect = rl.DrawRectangle
local draw_texture = rl.DrawTexturePro
local begin_drawing = rl.BeginDrawing
local clear = rl.ClearBackground
local end_drawing = rl.EndDrawing
local draw_fps = rl.DrawFPS

local asset_server = require 'lib.core.asset_server'

--- @class Context
local ctx = {}

--- @param texture_handle number
--- @param src_rect number[]
--- @param dest_rect number[]
--- @param origin number
--- @param rotation number
--- @param color number[]
function ctx.draw_texture(texture_handle, src_rect, dest_rect, origin, rotation, color)
  local texture = asset_server.get_handle_value(texture_handle)
  draw_texture(texture, src_rect, dest_rect, origin, rotation, color)
end

--- @param x number
--- @param y number
function ctx.draw_fps(x, y)
  draw_fps(x, y)
end

return ctx
