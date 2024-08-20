# IMPORTANT: This flake is for testing only
{
  description = "A basic flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    lz-n = {
      url = "github:nvim-neorocks/lz.n";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    lz-n,
  }: let
    inherit (nixpkgs) lib;
    # Add your system here
    eachSystem = lib.genAttrs ["x86_64-linux"];
    pkgsFor = eachSystem (
      system:
        import nixpkgs {
          localSystem = system;
          overlays = [self.overlays.default];
        }
    );
  in {
    overlays = {
      default = final: _prev: {
        neovim-with-lzn = final.writeShellScriptBin "nvim-test" ''
          exec ${final.neovim-unwrapped}/bin/nvim --cmd "set rtp^=${lz-n}" "$@"
        '';
        run-lzn-test = final.writeShellScriptBin "run-test" ''
          exec ${final.neovim-with-lzn}/bin/nvim-test --headless +'luafile tests/test.lua' +q
        '';
      };
    };

    packages = eachSystem (system: {
      inherit (pkgsFor.${system}) neovim-with-lzn run-lzn-test;
    });

    devShells = eachSystem (system: let
      pkgs = pkgsFor.${system};
    in {
      default = pkgs.mkShell {
        shellHook = ''
          echo -e '\x1b[32m Hint: use the command `run-test` to run tests \x1b[0m'
        '';
        buildInputs = with pkgs; [neovim-with-lzn run-lzn-test];
      };
    });
  };
}
