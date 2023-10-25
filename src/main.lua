local App = require 'lib.app'

App()
    :add_plugin('lib.core')
    :add_plugin('examples.angry_bunnies')
    :run()
