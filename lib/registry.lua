local Array = require 'lib.array'

local Registry = {}
local uid = 0

Registry.RESERVED_WORDS = Array('entity', 'world', 'registry')
Registry.MAX_COMPONENTS = 256
Registry.MAX_ENTITIES = 32768

function Registry.get_components_count()
  return uid
end

--- @alias Component fun(...): { [1]: integer, [2]: any } | { [1]: integer }
--- @param scheme (table | string)?
--- @return Component
function Registry.create_component(scheme)
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

return Registry
