#!/bin/bash

# Load utility functions
source ./utils.sh

stty -icanon
PACKAGE_LIST=()

while true; do
    echo "Enter the package you need (search will be performed):"
    read -p "Package name: " PACKAGE

    SELECTED_PACKAGE=$(get_package_selection "$PACKAGE")
    PACKAGE_LIST+=("$SELECTED_PACKAGE")

    read -p "Would you like to add another package? (y/n): " ADD_ANOTHER
    if [[ "$ADD_ANOTHER" != "y" ]]; then
        break
    fi
done

generate_flake_nix $LANG "${PACKAGE_LIST[@]}"

# Restore terminal settings
stty icanon
