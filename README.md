# Nix Flake Builder

A simple shell script that assists in generating custom Nix flake configurations. The script allows users to select system architecture, programming language/runtime, and packages to include in a `flake.nix` file. Multiple packages can be added, and the resulting `flake.nix` file is saved in a unique directory.

## Features

- Choose system architecture (x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin, or custom).
- Select a language/runtime (Python, Node.js, Ruby, Go, Java, Rust, or custom).
- Search through Nix store to add multiple packages to the Nix flake configuration.
- Automatically generates a `flake.nix` file with the selected configurations.

## Requirements

- Nix package manager or NixOs
- `fzf` for fuzzy searching package names
- `jq` for JSON parsing

## Example Output

```nix
{
  description = "A simple system-aware Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
          nixpkgs.legacyPackages.x86_64-linux.python312Full
          nixpkgs.legacyPackages.x86_64-linux.python312Packages.jupyterlab
          nixpkgs.legacyPackages.x86_64-linux.python312Packages.numpy
          nixpkgs.legacyPackages.x86_64-linux.python312Packages.pandas
          ];

          shellHook = ''
            export PS1="\[\033[1;34m\][nix-dev:\w]$ \[\033[0m\]"
            echo -e "\033[1;32m==> Entering Nix development shell on ''${system}\033[0m"
            echo -e "\033[1;34mPackages available:\033[0m"
            echo ''${buildInputs} | tr ' ' '\n' | sed 's/^/  - /'
          '';
        };
      }
    );
}
```