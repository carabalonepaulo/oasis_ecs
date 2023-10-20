local Object = require 'vendor.object'

--- @class Uid
--- @overload fun(): Uid
local Uid = Object:extend()

--- @private
function Uid:new()
  self._available = {}
  self._highest = 0
end

--- @return integer
function Uid:next()
  if #self._available > 0 then
    return table.remove(self._available)
  end
  self._highest = self._highest + 1
  return self._highest
end

--- @param id integer
function Uid:free(id)
  table.insert(self._available, id)
end

return Uid
