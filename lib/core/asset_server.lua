local Slab = require 'lib.slab'
local Queue = require 'lib.queue'

local textures = Slab(1024)
local handlers = {}
local mirror = {}
local events = Queue()

local rl = require 'lib.raylib'
local load_texture = rl.LoadTexture

--- @param ext string
--- @param handler fun(path): any
local function register_handler(ext, handler)
  assert(handlers[ext] == nil, 'Handler for extension ' .. ext .. ' already registered!')
  handlers[ext] = handler
end

--- @param path string
--- @return integer
local function load(path)
  if mirror[path] then
    return mirror[path]
  end

  local ext = path:get_file_extension()
  assert(handlers[ext], "Can't load this kind of file.")

  local id = textures:insert(handlers[ext]('./assets/' .. path))
  mirror[path] = id
  events:enqueue({ 'texture_loaded', id })
  return id
end

--- @param id integer
local function get_handle_value(id)
  return textures[id]
end

register_handler('png', function(path) --- @param path string
  local texture = load_texture(path)
  assert(texture.id > 0, 'Failed to load texture: ' .. path)
  return texture
end)

--- @param world World
local function notify(world)
  for event_data in events:iter() do
    world:emit('asset_server', unpack(event_data))
  end
end

--- @param app App
local function plugin(app)
  app
      :add_event_domain('asset_server')
      :add_system(notify, 'always')
end

return {
  plugin = plugin,
  load = load,
  register_handler = register_handler,
  get_handle_value = get_handle_value
}
