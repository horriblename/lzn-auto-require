# lz.n auto require

Implements a simple lua module loader that searches opt plugins and call lz.n hooks to ensure
proper plugin initialization.

## Usage

**Recommended**: place this code in `after/plugin/lzn-auto-require.lua`. It's easy to accidentally
require a module in the init stage, which defeats the purpose of lazy loading. Registering the
loader as late as possible reduces such mistakes. This is not always feasible for everyone, but you
can also put this in your init.lua normally

```lua
require('lzn-auto-require.loader').register_loader()
```

Afterwards, any call to `require` will also look for the lua module in `(packpath)/opt/*/lua`,
and `require("lz.n").trigger_load` will be called if a matching module is found.
