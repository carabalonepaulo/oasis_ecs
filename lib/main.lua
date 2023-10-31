local Array = require 'lib.array'
local World = require 'lib.world'

local function create_dispatch_table(known_domains, when)
  local dispatch_table = {}
  local when_len = #when

  known_domains:each(function(domain_name)
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

  return dispatch_table
end

local function execute_system(world, system, cond_list, ...)
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

return function(qualified, known_domains)
  local world = World()
  local dispatch_table = create_dispatch_table(known_domains, qualified.when)

  local once = qualified.once
  local once_len = #once
  local always = qualified.always
  local always_len = #always

  local meta

  for i = 1, once_len do
    meta = rawget(once, i)
    execute_system(world, meta[1], meta[3])
  end

  while not world.should_quit do
    for i = 1, always_len do
      meta = rawget(always, i)
      execute_system(world, meta[1], meta[3])
    end

    for event_data in world.events:iter() do
      local callbacks = dispatch_table[event_data[1]][event_data[2]]
      if callbacks then
        for i = 1, #callbacks do
          execute_system(world, callbacks[i][1], callbacks[i][2], unpack(event_data[3]))
        end
      end
    end
  end
end
