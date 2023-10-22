local App = require 'lib.app'
local create_component = App.create_component

return {
  position = create_component(),
  size = create_component(),
  debug_rect = create_component(),
  color = create_component(),
}
