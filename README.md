# lz.n auto require

Implements a simple lua module loader that searches opt plugins and call lz.n hooks to ensure
proper plugin initialization.

## Usage

Place this code somewhere in your config, and call it as **late** as possible (e.g. at the bottom
of your init.lua). 

```lua
require('lzn-auto-require.loader').register_loader()
```

> [!TIP]
>
> It's easy to accidentally require a module in your init.lua, which defeats the purpose of lazy
> loading. Registering the loader as late as possible reduces such mistakes.

After registering the loader, any call to `require` will also look for the lua module in
`(packpath)/opt/*/lua`.
