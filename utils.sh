#!/bin/bash

# Function to search for packages in the Nix package store
search_package() {
    local package_name=$1
    echo "Searching for package '${package_name}' in the Nix package store..."
    nix search nixpkgs "$package_name" --json | jq -r 'to_entries[] | "\(.key) - \(.value.description)"' || echo "No results found for '${package_name}'."
}

# Function to refine package selection and prompt the user
get_package_selection() {
    local package_name=$1
    local results
    local selected_package
    
    # Run search and store results
    results=$(nix search nixpkgs "$package_name" --json)
    
    # Display results to stderr so they don't get captured
    echo "Found the following packages matching '${package_name}':" >&2
    echo "$results" | jq -r 'to_entries[] | "\(.key) - \(.value.description)"' | nl -w 2 -s ') ' >&2
    
    # Get user selection
    echo -n "Please choose a package (enter number or type 'custom' for manual input): " >&2
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        # Get the full package name
        selected_package=$(echo "$results" | \
            jq -r 'to_entries[] | .key' | \
            sed -n "${choice}p" )
    else
        echo -n "Please enter the custom package name: " >&2
        read -r selected_package
    fi
    
    # Return the full package name (with version and architecture)
    echo "$selected_package"
}


generate_flake_nix() {
    shift 1
    local PACKAGES=("$@")
    # Create the directory
    DIR=~/generated_flake
    mkdir -p "$DIR"
    
    # Create flake.nix with the minimal required content
    cat > "${DIR}/flake.nix" <<'EOF'
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
EOF

    # Add packages
    for PACKAGE in "${PACKAGES[@]}"; do
        echo "nixpkgs.${PACKAGE}" >> "${DIR}/flake.nix"
    done

    # Continue the flake definition
    cat >> "${DIR}/flake.nix" <<'EOF'
          ];

          shellHook = ''
            export PS1="\[\033[1;32m\](dev)\[\033[0m\] $PS1"

            echo "Entering dev environment on ${system}"
          '';
        };
      }
    );
}
EOF
    echo "Your flake.nix has been saved to ${DIR}/flake.nix"
}