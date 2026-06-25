#!/bin/bash
# setup-sandbox-user.sh — Create the sandbox OS user and set ownership.
# Creates group/user with fixed GID/UID 10001 for consistent non-root isolation.
# Pre-creates named-volume mountpoints so Docker seeds them sandbox-owned;
# without this, volumes initialise root-owned and the sandbox user cannot write to them.

groupadd --gid 10001 sandbox
useradd --uid 10001 --gid sandbox --create-home --shell /bin/bash sandbox
mkdir -p /home/sandbox/.dbtools /home/oracle/logs
chown -R sandbox:sandbox /usr/sandbox/app /home/sandbox/.dbtools /home/oracle/logs
# Grant read/execute access to Oracle components for the sandbox user (files ship as rw-r----- root:root)
chmod -R o+r /opt/oracle/sqlcl/lib
chmod o+x /opt/oracle/sqlcl/bin/sql
chmod -R o+rX /opt/oracle/apex
# Grant write access to ORDS config directory so sandbox user can install/configure ORDS
chmod -R o+rwX /opt/oracle/ords
