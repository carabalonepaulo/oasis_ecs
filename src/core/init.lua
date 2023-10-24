--- @param app App
return function(app)
  app
      :add_plugin('src.core.state')
      :add_plugin('src.core.window')
      :add_plugin('src.core.renderer')
end
