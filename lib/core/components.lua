local create_component = require('lib.app').create_component

return {
  position = create_component { 'number', 'number', 'number' },
  scale = create_component { 'number', 'number' },
  size = create_component { 'number', 'number' },
  color = create_component { 'number', 'number', 'number', 'number' },
  texture = create_component('string'),

  camera_2d = create_component()
}
