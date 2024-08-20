# lz.n auto require

Implements a simple lua module loader that searches opt plugins and call
[lz.n](https://github.com/nvim-neorocks/lz.n) hooks to ensure proper plugin initialization.

## Usage

Place this code somewhere in your config, and call it as **late** as possible (e.g. at the bottom
of your init.lua). 

```lua
require('lzn-auto-require.loader').register_loader()
```

> [!TIP]
>
> It's easy to accidentally require a module that you want to lazy-load in your init.lua, which
> defeats the purpose of lazy loading. Registering the loader as late as possible reduces such
> mistakes.

After registering the loader, any call to `require` will also look for the lua module in
`(packpath)/opt/*/lua`.

## Nix

The flake is currently only used for development. Please build this plugin normally with
`buildVimPlugin` as shown in [nixos wiki](https://wiki.nixos.org/wiki/Vim#Add_a_new_custom_plugin_to_the_users_packages)

# Acknowledgements

Thank you to the lz.n authors for their great work!

Part of the code base uses code from lz.n, also licensed under GPL-2
