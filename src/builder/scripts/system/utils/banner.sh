#!/bin/bash

#########################################################################
#                                                                       #
#                    Shared Banner Function                            #
#                       Demasy Labs Utils                              #
#                                                                       #
#########################################################################

# Source colors if not already loaded
if [ -z "$RED" ]; then
    _BANNER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$_BANNER_SCRIPT_DIR/colors.sh"
fi

# Function to print Demasy Labs banner
# Usage: print_demasy_banner "Your Title Here"
print_demasy_banner() {
    local title="${1:-Banner}"
    
    clear
    echo ""
    echo -e "\e[0;33m ____  _____ __  __    _    ______   __\e[0m"
    echo -e "\e[0;33m|  _ \| ____|  \/  |  / \  / ___\ \ / /\e[0m"
    echo -e "\e[0;33m| | | |  _| | |\/| | / _ \ \___ \\\\ V /\e[0m" 
    echo -e "\e[0;33m| |_| | |___| |  | |/ ___ \ ___) || |\e[0m"
    echo -e "\e[0;33m|____/|_____|_|  |_/_/   \_\____/ |_|\e[0m"
    echo ""
    echo -e "                             \e[0;33m\e[5mL A B S\e[0m"
    echo ""
    echo -e "\e[0;33mDeveloped by: \e[1m\e[0;33mDemasy Labs\e[0m\e[0;33m 🚀\e[0m"
    echo -e "\e[0;33m-----------------------------------------------------\e[0m"    
    echo -e "\e[0;33m        Code with love ❤️  in Egypt \e[0m"
    echo ""
    echo ""
    echo -e "\e[1m************* ${title} ************* \e[0m"
    echo ""
}

# Usage in scripts:
# source "$(dirname "$0")/../utils/banner.sh"
# print_demasy_banner "Database Connection"
