local current_state

--- @param world World
local function setup(world)
  world:emit('state', 'change', 'boot')
end

--- @param world World
--- @param next_state string
local function change_state(world, next_state)
  if current_state then
    world:emit('state', 'exit_' .. current_state)
  end

  current_state = next_state
  world:emit('state', 'enter_' .. next_state)
  world:emit('state', 'changed', next_state)
end

--- @param app App
return function(app)
  app
      :add_event_domain('state')
      :add_system(setup, 'once')
      :add_system(change_state, 'when', 'state.change')
end
