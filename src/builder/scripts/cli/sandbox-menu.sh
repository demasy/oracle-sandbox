# ─── sandbox interactive menu library ─────────────────────────────────────────
# Reusable functions for interactive CLI menus and prompts
# Sourced by action scripts that need user interaction
# ─────────────────────────────────────────────────────────────────────────────

# Display a menu and return the selected option number
# Usage: _menu_select "title" "option1" "option2" "option3"
# Returns: selected option number (1-based)
_menu_select() {
    local title="$1"
    shift
    local options=("$@")
    local num_options=${#options[@]}
    
    echo ""
    echo -e "  ${WHITE}${title}${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        echo -e "    ${CYAN}$((i + 1))${NC}) ${options[i]}"
    done
    
    echo ""
    printf "  ${YELLOW}Select (1-${num_options}):${NC} "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= num_options)); then
        echo "$choice"
        return 0
    else
        log_error "Invalid selection"
        return 1
    fi
}

# Display a confirmation prompt
# Usage: _confirm "prompt message"
# Returns: 0 if user confirms (y/Y), 1 if user declines
_confirm() {
    local prompt="$1"
    
    printf "  ${YELLOW}${prompt}${NC} (${CYAN}y${NC}/${CYAN}n${NC}) "
    read -r response
    
    [[ "$response" =~ ^[yY] ]]
}

# Prompt user for text input
# Usage: _prompt_input "prompt message" "variable_name"
# Sets the variable_name to user input
_prompt_input() {
    local prompt="$1"
    local var_name="$2"
    
    printf "  ${YELLOW}${prompt}:${NC} "
    read -r user_input
    
    eval "${var_name}='${user_input}'"
}

# Display a password prompt (hidden input)
# Usage: _prompt_password "prompt message" "variable_name"
# Sets the variable_name to user input (hidden)
_prompt_password() {
    local prompt="$1"
    local var_name="$2"
    
    printf "  ${YELLOW}${prompt}:${NC} "
    read -rs user_password
    echo ""
    
    eval "${var_name}='${user_password}'"
}

# Display a multi-choice menu (with descriptions)
# Usage: _menu_select_with_descriptions "title" "option1:description1" "option2:description2"
_menu_select_with_descriptions() {
    local title="$1"
    shift
    local options=("$@")
    local num_options=${#options[@]}
    
    echo ""
    echo -e "  ${WHITE}${title}${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        IFS=':' read -r opt desc <<< "${options[i]}"
        printf "    ${CYAN}%d${NC}) %-25s ${YELLOW}%s${NC}\n" $((i + 1)) "$opt" "$desc"
    done
    
    echo ""
    printf "  ${YELLOW}Select (1-${num_options}):${NC} "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= num_options)); then
        echo "$choice"
        return 0
    else
        log_error "Invalid selection"
        return 1
    fi
}

# Display a progress spinner while waiting for a command
# Usage: _spinner "message" & command_pid=$!; wait $command_pid
_spinner() {
    local message="$1"
    local pid=$!
    local spin=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    
    while kill -0 $pid 2>/dev/null; do
        for i in "${!spin[@]}"; do
            printf "  ${CYAN}${spin[i]}${NC} ${message}...\r"
            sleep 0.1
        done
    done
    printf "  ✓ ${message}...done\n"
}

# Display a list with bullet points
# Usage: _list_items "option1" "option2" "option3"
_list_items() {
    local items=("$@")
    
    for item in "${items[@]}"; do
        echo -e "    ${CYAN}•${NC} $item"
    done
}

# Display a key-value pair table
# Usage: _show_table "header1:header2:header3" "val1:val2:val3" "val4:val5:val6"
_show_table() {
    local header="$1"
    shift
    local rows=("$@")
    
    # Display header
    IFS=':' read -ra header_cols <<< "$header"
    printf "  "
    for col in "${header_cols[@]}"; do
        printf "${CYAN}%-25s${NC}  " "$col"
    done
    echo ""
    echo "  ─────────────────────────────────────────────────────────"
    
    # Display rows
    for row in "${rows[@]}"; do
        IFS=':' read -ra cols <<< "$row"
        printf "  "
        for col in "${cols[@]}"; do
            printf "%-25s  " "$col"
        done
        echo ""
    done
    echo ""
}

# Display a section with title and content
# Usage: _show_section "title" "content line 1" "content line 2"
_show_section() {
    local title="$1"
    shift
    local content=("$@")
    
    echo ""
    echo -e "  ${WHITE}${title}${NC}"
    echo "  ─────────────────────────────────────────────────────────"
    for line in "${content[@]}"; do
        echo "  $line"
    done
    echo ""
}

# Prompt for multiple values with a loop
# Usage: _prompt_until_valid "prompt" "validator_function"
_prompt_until_valid() {
    local prompt="$1"
    local validator_func="$2"
    
    while true; do
        _prompt_input "$prompt" input_value
        if $validator_func "$input_value"; then
            break
        fi
    done
}

# Display a warning box
# Usage: _warn_box "warning message"
_warn_box() {
    local msg="$1"
    echo ""
    echo -e "  ${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${YELLOW}│${NC} ${msg:0:51}                          ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display a success box
# Usage: _success_box "success message"
_success_box() {
    local msg="$1"
    echo ""
    echo -e "  ${GREEN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${GREEN}│${NC} ✓ ${msg:0:47}                    ${GREEN}│${NC}"
    echo -e "  ${GREEN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display an error box
# Usage: _error_box "error message"
_error_box() {
    local msg="$1"
    echo ""
    echo -e "  ${RED}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${RED}│${NC} ✗ ${msg:0:47}                    ${RED}│${NC}"
    echo -e "  ${RED}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}
