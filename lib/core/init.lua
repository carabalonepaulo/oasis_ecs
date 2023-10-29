local asset_server_plugin = require('lib.core.asset_server').plugin

--- @param app App
return function(app)
  app
      :add_plugin(asset_server_plugin)
      :add_plugin('lib.core.state')
      :add_plugin('lib.core.window')
      :add_plugin('lib.core.renderer')
end
