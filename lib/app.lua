local Object = require 'vendor.object'
local Array = require 'lib.array'
local Slab = require 'lib.slab'
local Queue = require 'lib.queue'

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
      return { component_id, value or 1 }
    end
  })

  return ctor --[[@as Component]]
end

---

--- @class World
--- @field should_quit boolean If true the app will close on the next iteration.
local World = Object:extend()

--- @alias Entity integer

--- @private
function World:new()
  self.entities = Slab(Registry.MAX_ENTITIES)
  self.components = Array.with_capacity(Registry.MAX_COMPONENTS)

  for i = 1, Registry.MAX_COMPONENTS do
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

--- @param event string event name
--- @param ... any args
function World:emit(event, ...)
  self.events:push_right({ event, { ... } })
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

    while entity < Registry.MAX_ENTITIES do
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

---

--- @alias System fun(world: World)
--- @class App
--- @field systems System[]
--- @field qualified { once: System[], always: System[], every: System[], when: System[] }
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
    every = Array(),
    when = Array(),
  }
  self.world = World()
end

--- @param system fun(world: World)
--- @param qualifier 'once' | 'always' | 'every' | 'when'
--- @param cond_or_interval_or_event (fun(world: World) | number | string)?
function App:add_system(system, qualifier, cond_or_interval_or_event)
  if qualifier == 'when' then
    assert(cond_or_interval_or_event, 'No event specified.')
  end

  if qualifier == 'every' then
    assert(cond_or_interval_or_event, 'No interval specified.')
  end

  assert(Array('once', 'always', 'every', 'when'):find(qualifier) ~= -1, 'Invalid qualifier ' .. qualifier)

  table.insert(self.systems, system)
  self.qualified[qualifier or 'always']:insert({ system, cond_or_interval_or_event })
  return self
end

--- @param arg string | fun(app: App)
--- @return App
function App:add_plugin(arg)
  local arg_type = type(arg)
  if arg_type == 'string' then
    require(arg)(self)
  elseif arg_type == 'function' then
    arg(self)
  end
  return self
end

function App:run()
  local world = self.world
  local dispatch_table = {}
  local when = self.qualified.when
  local when_len = #when

  for i = 1, when_len do
    local ev_func = when[i][1]
    local ev_name = when[i][2]

    if not dispatch_table[ev_name] then
      dispatch_table[ev_name] = Array()
    end
    dispatch_table[ev_name]:insert(ev_func)
  end

  local function execute_system(meta)
    if #meta == 2 then
      if meta[2](world) then
        meta[1](world)
      end
    else
      meta[1](world)
    end
  end

  local once = self.qualified.once
  local once_len = #once
  local always = self.qualified.always
  local always_len = #always

  for i = 1, once_len do
    execute_system(rawget(once, i))
  end
  while not world.should_quit do
    for i = 1, always_len do
      execute_system(rawget(always, i))
    end

    for event_data in world.events:iter() do
      local callbacks = dispatch_table[event_data[1]]
      if callbacks then
        for i = 1, #callbacks do
          callbacks[i](world, unpack(event_data[2]))
        end
      end
    end
  end
end

return App
