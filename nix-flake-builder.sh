#!/bin/bash

# Load utility functions

source ./utils.sh

stty -icanon

# Step 1: Get system architecture

echo "Please select your system architecture:"
echo "1) x86_64-linux"
echo "2) aarch64-linux"
echo "3) Other (please type manually)"
read -p "Select an option (1/2/3): " ARCH_CHOICE

ARCH=$(get_system_architecture $ARCH_CHOICE)

# Step 2: Choose the language/runtime (with fuzzy search support)

echo "Please choose a language/runtime (Enter corresponding number or type custom language):"

LANGUAGES=("python3" "nodejs" "ruby" "go" "java" "rust")

LANG=$(select_language "${LANGUAGES[@]}")

# Step 3: Search for packages (fuzzy search)

echo "Enter the package you need (search will be performed):"
read -p "Package name: " PACKAGE

SELECTED_PACKAGE=$(get_package_selection "$PACKAGE")

# Step 4: Generate the flake.nix file

generate_flake_nix $ARCH $LANG "$SELECTED_PACKAGE"

echo "Your custom flake.nix has been generated!"

# Restore terminal settings
stty icanon