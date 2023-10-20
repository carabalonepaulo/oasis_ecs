local Object = require 'vendor.object'
local Array = require 'lib.array'
local Slab = require 'lib.slab'
local Uid = require 'lib.uid'
local printf = function(...) print(string.format(...)) end

---

local Registry = {}
local uid = 0

Registry.RESERVED_WORDS = Array('entity', 'world', 'registry')
Registry.MAX_COMPONENTS = 1024
Registry.MAX_ENTITIES = 1024

function Registry.get_components_count()
  return uid
end

--- @alias Component fun(...): { [1]: integer, [2]: any } | { [1]: integer }
--- @return Component
function Registry.create_component()
  uid = uid + 1
  local component_id = uid

  --- @overload fun(...): { [1]: integer, [2]: any }
  local ctor = setmetatable({ component_id }, {
    __call = function(_, value)
      return { component_id, value }
    end
  })

  return ctor --[[@as Component]]
end

---

--- @class World
local World = Object:extend()

--- @alias Entity integer

--- @private
function World:new()
  self.entities = Slab(Registry.MAX_ENTITIES)
  self.components = Array.with_capacity(Registry.MAX_COMPONENTS)

  for i = 1, Registry.get_components_count() do
    self.components[i] = Array.with_capacity(Registry.MAX_ENTITIES)
  end
end

--- @return integer
function World:spawn(...)
  -- local entity = self.entities:next()
  local entity_data = { components = Array() }
  entity_data.id = self.entities:insert(entity_data)

  -- printf('entity %d spawned', entity_data.id)

  local components = { ... }
  for _, meta in ipairs(components) do
    entity_data.components:insert(meta[1])
    -- printf('component %d added to entity %d with value `%s`', meta[1], entity_data.id, tostring(meta[2]))
    self.components[meta[1]][entity_data.id] = meta[2]
  end

  return entity_data.id
end

function World:despawn(entity)
  local entity_data = self.entities:get(entity)
  for _, component_id in ipairs(entity_data.components) do
    self.components[component_id][entity_data.id] = nil
  end
  self.entities:remove(entity)
end

function World:add_component(entity, component)
  local component_id = component[1]
  local component_value = component[2]
  local entity_data = self.entities:get(entity)

  if Array.find(entity_data.components, component_id) == -1 then
    entity_data.components:insert(component_id)
    -- self.components[component_id][entity_data.id] = component_value
    -- else
  end
  self.components[component_id][entity_data.id] = component_value
end

function World:remove_component(entity, component)
  -- self.components[component[1]][entity] = nil
  local entity_data = self.entities:get(entity)

  -- assert(Array.find(entity_data.components, component_id) ~= -1)
  self.components[component[1]][entity_data.id] = nil
end

--- @param ... Component
--- @return fun(): Entity?, ...
function World:query(...)
  local components = { ... }
  local last_entity = 0
  local result = Array.with_capacity(#components)

  return function()
    local entity = last_entity + 1
    local entity_data
    local result_len = #components

    while entity < Registry.MAX_ENTITIES do
      entity_data = self.entities:get(entity)
      if entity_data then
        break
      else
        entity = entity + 1
      end
    end

    if not entity_data then
      return nil
    end
    last_entity = entity

    local has_components = true
    for i = 1, result_len do
      if not self.components[components[i][1]][entity] then
        has_components = false
        break
      end
    end

    if has_components then
      for i = 1, result_len do
        result[i] = self.components[components[i][1]][entity]
      end
      return entity, unpack(result)
    end

    return nil
  end
end

---

--- @alias System fun(world: World)
--- @class App
--- @field systems System[]
--- @field qualified { once: System[], always: System[], every: System[] }
--- @field world World
--- @overload fun(): App
local App = Object:extend()

App.create_component = Registry.create_component

--- @private
function App:new()
  self.systems = Array()
  self.qualified = {
    once = Array(),
    always = Array(),
    every = Array()
  }
  self.world = World()
end

--- @param system fun(world: World)
--- @param qualifier 'once' | 'always' | 'every'
--- @param cond_or_interval (fun(world: World) | number)?
function App:add_system(system, qualifier, cond_or_interval)
  table.insert(self.systems, system)
  self.qualified[qualifier or 'always']:insert({ system, cond_or_interval })
  return self
end

--- @param path string
--- @return App
function App:add_plugin(path)
  require(path)(self)
  return self
end

function App:run()
  local function execute_system(meta)
    if #meta == 2 then
      if meta[2](self.world) then
        meta[1](self.world)
      end
    else
      meta[1](self.world)
    end
  end

  local once = self.qualified.once
  local once_len = #once
  local always = self.qualified.always
  local always_len = #always

  for i = 1, once_len do
    execute_system(rawget(once, i))
  end
  while true do
    for i = 1, always_len do
      execute_system(rawget(always, i))
    end
  end
end

return App

---

-- local Name = Component()

-- --- @param world World
-- local function condition(world)
--   for entity, name in world:query(Name) do
--     -- world:query()
--   end
--   return false
-- end

-- --- @param world World
-- local function hello_world(world)
--   local entity = world:spawn(Name('foo'))
--   print('hello world system executed')
-- end

-- local function print_names(world)
--   for entity, name in world:query(Name) do
--     print(entity, name, 'jasd')
--   end
--   print('print names')
-- end

-- App()
-- -- :add_system(hello_world)
--     :add_system(hello_world, 'once')
--     :add_system(print_names, 'once')
-- -- :add_system(hello_world, 'once', condition)
--     :run()
