require 'ext.math'
require 'ext.os'
require 'ext.string'
require 'ext.table'

local Object = require 'vendor.object'
local Array = require 'lib.array'
local Slab = require 'lib.slab'
local Queue = require 'lib.queue'
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

--- @overload fun(self: World, event: string, ...: any)
--- @param group string event group
--- @param event string event name
--- @param ... any args
function World:emit(group, event, ...)
  local temp, args

  -- world:emit('group', 'event')
  if event ~= nil then
    args = { ... }
  else -- world:emit('event')
    temp = event
    event = group
    group = '__default'
    args = { temp, ... }
  end

  self.events:push_right({ group, event, args })
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

---

--- @alias System fun(world: World)
--- @alias Condition fun(world: World): boolean

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

--- @alias SystemQualifier 'once' | 'always' | 'every' | 'when'
---
--- @overload fun(self: App, system: System, qualifier: 'once', ...: Condition?)
--- @overload fun(self: App, system: System, qualifier: 'always', ...: Condition?)
--- @overload fun(self: App, system: System, qualifier: 'every', interval: number, ...: Condition?)
--- @overload fun(self: App, system: System, qualifier: 'when', event: string, ...: Condition?)
function App:add_system(system, qualifier, ...)
  qualifier = qualifier or 'always'

  local cond_list = { ... }
  local cond_list_len = #cond_list
  local second_arg = nil
  local assert_first_item = function(type_name, error_message)
    assert(cond_list_len >= 1 and type(cond_list[1]) == type_name, error_message)
  end

  if qualifier == 'every' then
    assert_first_item('number', 'Invalid interval.')
    second_arg = table.remove(cond_list, 1)
  elseif qualifier == 'when' then
    assert_first_item('string', 'Invalid event.')
    second_arg = table.remove(cond_list, 1)
  end

  assert(Array('once', 'always', 'every', 'when'):find(qualifier) ~= -1,
    'Invalid qualifier ' .. qualifier)
  table.insert(self.systems, system)
  self.qualified[qualifier]:insert({ system, second_arg, cond_list })

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
    local ev_name, ev_group
    local cond = when[i][3]

    local parts = when[i][2]:split('%.')
    local parts_len = #parts

    if parts_len == 1 then
      ev_group = '__default'
      ev_name = when[i][2]
    elseif parts_len == 2 then
      ev_group = parts[1]
      ev_name = parts[2]
    else
      error(string.format('Invalid event identifier: "%s"!', when[i][2]))
    end

    if not dispatch_table[ev_group] then
      dispatch_table[ev_group] = {}
    end

    if not dispatch_table[ev_group][ev_name] then
      dispatch_table[ev_group][ev_name] = Array()
    end

    dispatch_table[ev_group][ev_name]:insert({ ev_func, cond })
  end

  local function execute_system(system, cond_list, ...)
    local len = #cond_list
    if len > 0 then
      local can_execute = true
      for i = 1, len do
        if not cond_list[i](world) then
          can_execute = false
          break
        end
      end
      if can_execute then
        system(world, ...)
      end
    else
      system(world, ...)
    end
  end

  local once = self.qualified.once
  local once_len = #once
  local always = self.qualified.always
  local always_len = #always

  local meta

  for i = 1, once_len do
    meta = rawget(once, i)
    execute_system(meta[1], meta[3])
  end

  while not world.should_quit do
    for i = 1, always_len do
      meta = rawget(always, i)
      execute_system(meta[1], meta[3])
    end

    for event_data in world.events:iter() do
      local callbacks = dispatch_table[event_data[1]][event_data[2]]
      if callbacks then
        for i = 1, #callbacks do
          execute_system(callbacks[i][1], callbacks[i][2], unpack(event_data[3]))
        end
      end
    end
  end
end

return App
