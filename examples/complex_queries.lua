local create_component = require('lib.app').create_component

local name = create_component()
local age = create_component()
local sword = create_component()
local bow = create_component()

--- @param world World
local function complex_queries(world)
  world:spawn(name('guard'), age(26), sword)
  world:spawn(name('hunter'), age(32), bow)
  world:spawn(name('adventurer'), sword, bow)

  -- 'guard', 'adventurer'
  for _, name in world:query(name & sword) do print(name) end

  -- 'hunter', 'adventurer'
  for _, name in world:query(name & bow) do print(name) end

  -- 'adventurer'
  for _, name in world:query(name & sword & bow) do print(name) end

  -- 'guard', 'hunter', 'adventurer'
  for _, name in world:query(name & (sword | bow)) do print(name) end

  -- 'adventurer'
  -- for _, name in world:query(name & without(age)) do print(name) end

  -- 'guard', 'hunter'
  -- { 'and', { 'and', name, { 'or', sword, bow } }, age }
  -- for _, name in world:query(name & (sword | bow) & with(age)) do print(name) end

  -- 'guard', 'hunter', 'adventurer'
  -- for _, name in world:query(name & with(sword | bow)) do print(name) end
end

--- @param app App
return function(app)
  app:add_system(complex_queries, 'once')
end
