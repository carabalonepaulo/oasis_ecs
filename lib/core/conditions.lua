return {
  --- @param component Component
  --- @return Condition
  component_exists = function(component)
    return function(world)
      return world:query(component)() ~= nil
    end
  end
}
