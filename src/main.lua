local App = require 'lib.app'

App()
    :add_plugin('src.raylib')
    :add_plugin('src.world')
    :run()
