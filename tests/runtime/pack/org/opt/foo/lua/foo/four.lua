-- ensure requiring modules from same plugin works
local lib = require('foo.lib')

_G.foo_four_loaded_count = _G.foo_four_loaded_count + 1
return lib.addOne(3)
