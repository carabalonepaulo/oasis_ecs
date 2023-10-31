require 'ext.math'
require 'ext.os'
require 'ext.string'
require 'ext.table'

local Object = require 'vendor.object'
local Array = require 'lib.collections.array'
local main = require 'lib.main'

local Registry = require 'lib.registry'

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

  self._known_domains = Array('__default')
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
    local result = require(arg)
    local result_type = type(result)

    if result_type == 'function' then
      result(self)
    elseif result_type == 'table' and result.plugin and type(result.plugin) == 'function' then
      result.plugin(self)
    end
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
  main(self.qualified, self._known_domains)
end

return App
