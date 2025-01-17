#!/bin/bash

# # Function to get system architecture
# get_system_architecture() {
#   case "$(uname -m)" in 
#     x86_64) echo "x86_64-linux" ;; 
#     aarch64) echo "aarch64-linux" ;; 
#     arm64) echo "aarch64-darwin" ;; 
#     i386) echo "x86_64-darwin" ;; # Not entriely sure on this one
#     *) echo "unknown" ;; 
#   esac 
# } 

# # Get system architecture 
# ARCH=$(get_system_architecture)
# echo "Your system is ${ARCH}"

# # Function to map language choice to language
# select_language() {
#   # Use fzf for fuzzy search in the language options
#   SELECTED_LANG=$(echo "$@" | tr ' ' '\n' | fzf --prompt "Select language/runtime: " --height 20)
#   echo "$SELECTED_LANG"
# }

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
    # local ARCH=$1
    # local LANG=$2
    shift 2  # Skip ARCH and LANG
    local PACKAGES=("$@")

    # Create the directory
    DIR=~/generated_flake
    mkdir -p "$DIR"

    # Create flake.nix with the minimal required content
    cat > "${DIR}/flake.nix" <<EOF
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
        $(for PACKAGE in "${PACKAGES[@]}"; do echo "nixpkgs.${PACKAGE}"; done)
          ];

          shellHook = ''
            # Add (dev) to the start of PS1
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