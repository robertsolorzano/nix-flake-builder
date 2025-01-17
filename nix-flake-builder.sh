#!/bin/bash

# Constants
DIR=~/generated_flake
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Helper function to print colored output
print_status() {
    echo -e "${BLUE}==>${NC} $1" >&2
}

# Search for packages using fuzzy search
search_package() {
    local query=$1
    print_status "Searching Nix packages..."
    
    # Get all packages and pipe through fzf
    nix search nixpkgs "$query" --json | \
    jq -r 'to_entries[] | "\(.key) | \(.value.description)"' | \
    fzf --height 50% \
        --border \
        --header 'Select package (Press ESC to cancel, ENTER to select)' \
        --preview 'echo {} | cut -d"|" -f2 | tr -d "\n" | fold -s -w 100' \
        --preview-window='right:50%:wrap'
}

# Get package selection
get_package_selection() {
    local selected
    selected=$(search_package "$1")
    
    if [[ -n "$selected" ]]; then
        # Extract just the package name from the selection
        echo "$selected" | cut -d'|' -f1 | tr -d ' '
    else
        return 1
    fi
}

# Generate flake.nix file
generate_flake_nix() {
    local PACKAGES=("$@")
    
    # Create directory if it doesn't exist
    mkdir -p "$DIR"
    
    print_status "Generating flake.nix..."
    
    # Generate the flake.nix file
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
        echo "            ${PACKAGE}" >> "${DIR}/flake.nix"
    done

    # Complete the flake.nix
    cat >> "${DIR}/flake.nix" <<'EOF'
          ];

          shellHook = ''
            export PS1="\[\033[1;32m\][nix-dev]\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\]$ "
            echo -e "\033[1;32m==> Entering Nix development shell on ''${system}\033[0m"
            echo -e "\033[1;34mPackages available:\033[0m"
            echo ''${buildInputs} | tr ' ' '\n' | sed 's/^/  - /'
          '';
        };
      }
    );
}
EOF

    print_status "Flake generated at ${DIR}/flake.nix"
}

main() {
    # Check for required commands
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is required but not installed."
        echo "Install it with: nix-env -iA nixpkgs.fzf"
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed."
        echo "Install it with: nix-env -iA nixpkgs.jq"
        exit 1
    fi

    local PACKAGE_LIST=()
    
    print_status "Welcome to Nix Shell Generator!"
    
    while true; do
        echo
        print_status "Enter package name to search (or press Ctrl+C to finish):"
        read -r -p "> " PACKAGE_QUERY
        
        if [[ -z "$PACKAGE_QUERY" ]]; then
            continue
        fi
        
        if selected_package=$(get_package_selection "$PACKAGE_QUERY"); then
            PACKAGE_LIST+=("$selected_package")
            echo -e "${GREEN}Added${NC} $selected_package to package list"
            echo -e "${BLUE}Current packages:${NC} ${PACKAGE_LIST[*]}"
        fi
        
        echo
        read -r -p "Add another package? [Y/n] " response
        response=${response,,} # Convert to lowercase
        if [[ "$response" =~ ^(n|no)$ ]]; then
            break
        fi
    done
    
    if [ ${#PACKAGE_LIST[@]} -eq 0 ]; then
        print_status "No packages selected. Exiting..."
        exit 0
    fi
    
    generate_flake_nix "${PACKAGE_LIST[@]}"
    
    print_status "Ready to enter shell! Run: cd $DIR && nix develop"
}

# Run main function
main "$@"