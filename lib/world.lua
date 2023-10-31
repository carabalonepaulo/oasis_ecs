local Object = require 'vendor.object'
local Array = require 'lib.array'
local Slab = require 'lib.slab'
local Queue = require 'lib.queue'
local Registry = require 'lib.registry'

--- @class World
--- @field should_quit boolean If true the app will close on the next iteration.
local World = Object:extend()

--- @alias Entity integer

--- @private
function World:new()
  local components_count = Registry.get_components_count()

  self.entities = Slab(Registry.MAX_ENTITIES)
  self.components = Array.with_capacity(components_count)

  for i = 1, components_count do
    self.components[i] = Array.with_capacity(Registry.MAX_ENTITIES)
  end

  self.events = Queue()
  self.should_quit = false
end

--- @return integer
function World:spawn(...)
  local entity_data = { components = Array() }
  entity_data.id = self.entities:insert(entity_data)

  -- printf('entity %d spawned', entity_data.id)

  local components = { ... }
  for _, meta in ipairs(components) do
    entity_data.components:insert(meta[1])
    -- printf('component %d added to entity %d with value `%s`', meta[1], entity_data.id, tostring(meta[2]))
    self.components[meta[1]][entity_data.id] = meta[2] or true
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

--- @overload fun(self: World, event: string, ...: any)
--- @param domain string event domain
--- @param event string event name
--- @param ... any args
function World:emit(domain, event, ...)
  local temp, args

  -- world:emit('group', 'event')
  if event ~= nil then
    args = { ... }
  else -- world:emit('event')
    temp = event
    event = domain
    domain = '__default'
    args = { temp, ... }
  end

  self.events:push_right({ domain, event, args })
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
    local has_components = true

    while true do
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

      for i = 1, result_len do
        if not self.components[components[i][1]][entity] then
          has_components = false
          break
        end
      end

      if has_components then
        break
      else
        entity = entity + 1
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

--- @param ... Component
--- @return Entity?, ...
function World:query_first(...)
  return self:query(...)()
end

return World
