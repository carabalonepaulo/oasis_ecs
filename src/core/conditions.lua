return {
  --- @param component Component
  component_exists = function(component)
    --- @param world World
    return function(world)
      return world:query(component)
    end
  end
}
