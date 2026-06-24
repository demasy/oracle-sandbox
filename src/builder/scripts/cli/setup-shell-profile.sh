#!/bin/bash
# Append Sandbox CLI aliases and completions to both root and sandbox user
# shell profiles so they are available automatically on container startup.

# root profile
cat >> /root/.bashrc << 'EOF'

# Sandbox CLI
[[ -f /usr/sandbox/app/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/cli/sandbox-aliases.sh
[[ -f /usr/sandbox/app/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/cli/sandbox-completion.bash
EOF

# sandbox user profile
cat >> /home/sandbox/.bashrc << 'EOF'

# Sandbox CLI
[[ -f /usr/sandbox/app/cli/sandbox-aliases.sh ]] && source /usr/sandbox/app/cli/sandbox-aliases.sh
[[ -f /usr/sandbox/app/cli/sandbox-completion.bash ]] && source /usr/sandbox/app/cli/sandbox-completion.bash
EOF

chown sandbox:sandbox /home/sandbox/.bashrc
