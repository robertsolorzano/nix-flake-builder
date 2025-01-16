#!/bin/bash

# Function to get system architecture
get_system_architecture() {
  case $1 in
    1) echo "x86_64-linux" ;;
    2) echo "aarch64-linux" ;;
    3) read -p "Please enter your architecture (e.g., x86_64-linux): " ARCH
       echo "$ARCH" ;;
    *) echo "Invalid option!" ;;
  esac
}

# Function to map language choice to language
select_language() {
  # Use fzf for fuzzy search in the language options
  SELECTED_LANG=$(echo "$@" | tr ' ' '\n' | fzf --prompt "Select language/runtime: " --height 20)
  echo "$SELECTED_LANG"
}

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
    local ARCH=$1
    local LANG=$2
    local PACKAGE=$3

    # Create flake.nix with the minimal required content
    cat > flake.nix <<EOF
{
  description = "Custom Nix flake generated by the builder";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  outputs = { self, nixpkgs }: 
  {
    devShell.${ARCH} = nixpkgs.legacyPackages.${ARCH}.mkShell {
      buildInputs = [ 
        nixpkgs.${LANG}
        nixpkgs.${PACKAGE}
      ];
    };
  };
}
EOF
}