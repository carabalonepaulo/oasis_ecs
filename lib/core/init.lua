--- @param app App
return function(app)
  app
      :add_plugin('lib.core.asset_server')
      :add_plugin('lib.core.state')
      :add_plugin('lib.core.window')
      :add_plugin('lib.core.renderer')
end
