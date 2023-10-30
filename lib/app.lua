require 'ext.math'
require 'ext.os'
require 'ext.string'
require 'ext.table'

local Object = require 'vendor.object'
local Array = require 'lib.array'
local Slab = require 'lib.slab'
local Queue = require 'lib.queue'
local printf = function(...) print(string.format(...)) end

local Registry = require 'lib.registry'
local World = require 'lib.world'

--- @alias System fun(world: World)
--- @alias Condition fun(world: World): boolean

--- @class App
--- @field systems System[]
--- @field qualified { once: System[], always: System[], every: System[], when: System[] }
--- @field world World
--- @field private _known_domains Array
--- @overload fun(): App
local App = Object:extend()

App.create_component = Registry.create_component

App.MAX_COMPONENTS = Registry.MAX_COMPONENTS
App.MAX_ENTITIES = Registry.MAX_ENTITIES

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

  self._known_domains = Array()
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

--- @param domain_name string
--- @return App
function App:add_event_domain(domain_name)
  self._known_domains:insert(domain_name)
  return self
end

function App:run()
  local world = self.world
  local dispatch_table = {}
  local when = self.qualified.when
  local when_len = #when

  self._known_domains:each(function(domain_name)
    dispatch_table[domain_name] = {}
  end)

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
