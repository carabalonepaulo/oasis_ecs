local function system(_) return setmetatable({}, {}) end
local function component(_, _) return setmetatable({}, {}) end
local function query(...) end
local function printf(...) print(string.format(...)) end
local function App() return setmetatable({}, {}) end
local function resource(_, _) return setmetatable({}, {}) end
local function with(...) return {} end
local World = require('lib.world')

---

local Player = component()
local Position = component({ 0, 0 })
local Name = component('')

local startup = system {
  { World },

  function(world)
    local entity_a = world:spawn()
    world:add_components_to(entity_a, Player, Position(10, 10))

    world:spawn(Player, Position(5, 15))
  end
}

local name_them = system {
  { query('entity', with(Player)) },
  function(commands, players)
    local i = 1
    for entity in players:get_iter() do
      commands:entity(entity):add('player ' .. tostring(i))
      i = i + 1
    end
  end
}

local hello_world = system {
  { query(Name, with(Player)) },
  function(names)
    for name in names:get_iter() do
      printf('hello player %s', name)
    end
  end
}

local has_players = system {
  { query(Player) },
  function(players)
    return players:get_size() > 0
  end
}

App()
    :add_system(startup:run_once())
    :add_system(name_them:run_once())
    :add_system(hello_world
      :run_once()
      :run_if(has_players))
    :run()
