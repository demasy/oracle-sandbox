#!/bin/bash
# Run runtime services as non-root for better container isolation.
# Pre-create the named-volume mountpoints owned by sandbox so a freshly
# created volume inherits sandbox ownership (Docker seeds an empty named
# volume from the image directory's ownership/permissions). Without this,
# Docker creates the mountpoint root-owned and the sandbox user cannot
# write saved connections or logs into it.

groupadd --gid 10001 sandbox
useradd --uid 10001 --gid sandbox --create-home --shell /bin/bash sandbox
mkdir -p /home/sandbox/.dbtools /home/oracle/logs
chown -R sandbox:sandbox /usr/sandbox/app /home/sandbox/.dbtools /home/oracle/logs
