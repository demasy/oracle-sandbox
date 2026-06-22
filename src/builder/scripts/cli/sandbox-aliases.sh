#!/bin/bash
# ─── Sandbox CLI Aliases ──────────────────────────────────────────────────────
# Optional shell aliases for faster command entry
# Source this file in ~/.bashrc or ~/.zshrc to enable aliases
#
# Installation:
#   - Add to ~/.bashrc or ~/.zshrc:
#     [[ -f /usr/sandbox/app/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/cli/sandbox-aliases.sh
#   - Or run: echo 'source /usr/sandbox/app/cli/sandbox-aliases.sh' >> ~/.bashrc
#
# Usage Examples:
#   sb status database        # sandbox status database
#   sr sqlcl -u system        # sandbox run sqlcl -u system
#   sc list                   # sandbox conn list
#   sl apex                   # sandbox logs apex
#   ss database               # sandbox status database
#   si apex                   # sandbox install apex
#   sk apex                   # sandbox start apex
#   sp apex                   # sandbox stop apex
#   sx apex                   # sandbox restart apex
# ─────────────────────────────────────────────────────────────────────────────

# Source config to get SANDBOX_ALIASES
source /usr/sandbox/app/cli/sandbox-config.sh

# Define command aliases from SANDBOX_ALIASES map
alias sb='sandbox'
alias sr='sandbox run'
alias sc='sandbox conn'
alias sl='sandbox logs'
alias ss='sandbox status'
alias si='sandbox install'
alias sk='sandbox start'
alias sp='sandbox stop'
alias sx='sandbox restart'

# Additional convenience aliases
alias sdownload='sandbox download'
alias suninstall='sandbox uninstall'

# Monitoring shortcuts
alias sm='sandbox run monitor'
alias sma='sandbox run monitor active-connections'
alias smd='sandbox run monitor database-size'
alias smt='sandbox run monitor tablespace-usage'
alias smq='sandbox run monitor top-queries-cpu'
alias sml='sandbox run monitor archive-log-status'

# Common status checks
alias ssd='sandbox status database'
alias ssa='sandbox status apex'
alias ssm='sandbox status mcp'

# Common log viewing
alias slapex='sandbox logs apex'
alias slords='sandbox logs ords'
alias slall='sandbox logs all'
