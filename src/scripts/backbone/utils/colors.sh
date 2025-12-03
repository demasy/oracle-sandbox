#!/bin/bash

#########################################################################
#                                                                       #
#                    Shared Color Definitions                          #
#                       Demasy Labs Utils                              #
#                                                                       #
#########################################################################

# Standard color definitions for consistent terminal output
export RED='\033[0;91m'        # Bright Red - Errors
export GREEN='\033[0;92m'      # Bright Green - Success
export YELLOW='\033[1;33m'     # Bright Yellow - Warnings/Labels
export BLUE='\033[0;34m'       # Blue - Info
export PURPLE='\033[0;35m'     # Purple - Titles
export CYAN='\033[1;36m'       # Bright Cyan - Highlights
export WHITE='\033[1;97m'      # Bright White - Values
export NC='\033[0m'            # No Color - Reset

# Usage in scripts:
# source "$(dirname "$0")/../utils/colors.sh"
# echo -e "${GREEN}Success!${NC}"
