#!/bin/bash

# Load utility functions
source ./utils.sh

stty -icanon

# Step 1: Get system architecture
echo "Please select your system architecture:"
echo "1) x86_64-linux"
echo "2) aarch64-linux"
echo "3) x86_64-darwin"
echo "4) aarch64-darwin"
echo "5) Other (please type manually)"
read -p "Select an option (1/2/3/4/5): " ARCH_CHOICE

ARCH=$(get_system_architecture $ARCH_CHOICE)

# Step 2: Choose the language/runtime (with fuzzy search support)
echo "Please choose a language/runtime (Enter corresponding number or type custom language):"
LANGUAGES=("python3" "nodejs" "ruby" "go" "java" "rust")
LANG=$(select_language "${LANGUAGES[@]}")

# Step 3: Search for packages (fuzzy search)
PACKAGE_LIST=()

while true; do
    echo "Enter the package you need (search will be performed):"
    read -p "Package name: " PACKAGE

    SELECTED_PACKAGE=$(get_package_selection "$PACKAGE")
    PACKAGE_LIST+=("$SELECTED_PACKAGE")

    # Ask if the user wants to add another package
    read -p "Would you like to add another package? (y/n): " ADD_ANOTHER
    if [[ "$ADD_ANOTHER" != "y" ]]; then
        break
    fi
done

# Step 4: Generate the flake.nix file
generate_flake_nix $ARCH $LANG "${PACKAGE_LIST[@]}"

# Restore terminal settings
stty icanon
