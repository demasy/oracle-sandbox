#!/bin/bash
# setup-shell-profile.sh — Wire CLI aliases and bash completions into shell profiles.
# Appends lazy-load guards to /root/.bashrc and /home/sandbox/.bashrc so aliases
# and tab-completion are available automatically in every interactive shell session.

# root profile
cat >> /root/.bashrc << 'EOF'

# Sandbox CLI
[[ -f /usr/sandbox/app/system/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/system/cli/sandbox-aliases.sh
[[ -f /usr/sandbox/app/system/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/system/cli/sandbox-completion.bash
EOF

# sandbox user profile
cat >> /home/sandbox/.bashrc << 'EOF'

# Terminal fix (suppress bracketed-paste noise on docker exec attach)
[ -z "$TERM" ] || [ "$TERM" = "dumb" ] && export TERM=xterm-256color
bind "set enable-bracketed-paste off" 2>/dev/null || true

# Sandbox CLI
[[ -f /usr/sandbox/app/system/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/system/cli/sandbox-aliases.sh
[[ -f /usr/sandbox/app/system/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/system/cli/sandbox-completion.bash
EOF

chown sandbox:sandbox /home/sandbox/.bashrc
