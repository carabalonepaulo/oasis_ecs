--- @param ... string
--- @return { from: fun(path: string): ... }
return function(...)
  -- import('position', 'size', 'debug_rect', 'color').from('src.raylib.components')
  local keys = { ... }
  return {
    from = function(path)
      local items = {}
      local mod = require(path)
      for _, key in ipairs(keys) do
        table.insert(items, mod[key])
      end
      return unpack(items)
    end
  }
end
