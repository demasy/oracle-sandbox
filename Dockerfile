# Stage 1: Build Stage
FROM node:20-bookworm-slim AS demasylabs-builder

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends curl unzip ca-certificates && \
  rm -rf /var/lib/apt/lists/*

ARG SRC_ORACLE_SQLCL
ARG SRC_ORACLE_SQLPLUS
ARG SRC_ORACLE_APEX
ARG SRC_ORACLE_ORDS
ARG INSTALL_APEX
ENV SRC_ORACLE_SQLCL=$SRC_ORACLE_SQLCL
ENV SRC_ORACLE_SQLPLUS=$SRC_ORACLE_SQLPLUS
ENV SRC_ORACLE_APEX=$SRC_ORACLE_APEX
ENV SRC_ORACLE_ORDS=$SRC_ORACLE_ORDS
ENV INSTALL_APEX=$INSTALL_APEX

RUN mkdir -p /usr/sandbox/app/cli
RUN mkdir -p /usr/sandbox/app/system/utils
RUN mkdir -p /usr/sandbox/app/system/build
RUN mkdir -p /usr/sandbox/app/system/admin
RUN mkdir -p /usr/sandbox/app/system/download
RUN mkdir -p /usr/sandbox/app/system/install
RUN mkdir -p /usr/sandbox/app/oracle/admin
RUN mkdir -p /usr/sandbox/app/oracle/apex
RUN mkdir -p /usr/sandbox/app/oracle/mcp
RUN mkdir -p /usr/sandbox/app/oracle/sqlcl
RUN mkdir -p /usr/sandbox/app/oracle/sqlplus

COPY package*.json ./

WORKDIR /usr/sandbox/app

COPY ./app.js ./app.js
# COPY ./src ./src
COPY ["LICENSE", "./"]

# Copy scripts to organized structure
COPY ./src/builder/scripts/cli/*.sh                 /usr/sandbox/app/cli/
COPY ./src/builder/scripts/system/utils/*.sh        /usr/sandbox/app/system/utils/
COPY ./src/builder/scripts/system/build/*.sh        /usr/sandbox/app/system/build/
COPY ./src/builder/scripts/system/admin/*.sh        /usr/sandbox/app/system/admin/
COPY ./src/builder/scripts/system/download/*.sh     /usr/sandbox/app/system/download/
COPY ./src/builder/scripts/system/install/*.sh      /usr/sandbox/app/system/install/
COPY ./src/builder/scripts/oracle/admin/*.sh        /usr/sandbox/app/oracle/admin/
COPY ./src/builder/scripts/oracle/apex/*.sh         /usr/sandbox/app/oracle/apex/
COPY ./src/builder/scripts/oracle/mcp/*.sh          /usr/sandbox/app/oracle/mcp/
COPY ./src/builder/scripts/oracle/sqlcl/*.sh        /usr/sandbox/app/oracle/sqlcl/
COPY ./src/builder/scripts/oracle/sqlplus/*.sh      /usr/sandbox/app/oracle/sqlplus/

# Set permissions for all scripts
RUN chmod +x /usr/sandbox/app/cli/*.sh && \
    chmod +x /usr/sandbox/app/system/utils/*.sh && \
    chmod +x /usr/sandbox/app/system/build/*.sh && \
    chmod +x /usr/sandbox/app/system/admin/*.sh && \
    chmod +x /usr/sandbox/app/system/download/*.sh && \
    chmod +x /usr/sandbox/app/system/install/*.sh && \
    chmod +x /usr/sandbox/app/oracle/admin/*.sh && \
    chmod +x /usr/sandbox/app/oracle/apex/*.sh && \
    chmod +x /usr/sandbox/app/oracle/mcp/*.sh && \
    chmod +x /usr/sandbox/app/oracle/sqlcl/*.sh && \
    chmod +x /usr/sandbox/app/oracle/sqlplus/*.sh

WORKDIR /usr/sandbox/app
RUN mkdir -p /opt/oracle

# Install Oracle components (Instant Client + SQLcl)
ENV TERM=xterm
RUN /usr/sandbox/app/system/build/builder-startup.sh

# Download APEX and ORDS using download-apex.sh script (conditional)
RUN if [ "$INSTALL_APEX" = "true" ]; then \
      /usr/sandbox/app/system/download/download-apex.sh; \
    else \
      echo "Skipping APEX/ORDS download (INSTALL_APEX=$INSTALL_APEX)"; \
    fi

# # Download and install SQL*Plus
# # Updated by demasy on November 11, 2025
# # Added SQL*Plus support alongside SQLcl for enhanced Oracle client compatibility
# # Note: Automatically detects architecture and provides appropriate solution
# RUN ARCH=$(uname -m) && \
#   if [ "$ARCH" = "x86_64" ]; then \
#     curl -L -o /tmp/sqlplus.zip "$SRC_ORACLE_SQLPLUS" && \
#     unzip -q /tmp/sqlplus.zip -d /opt/oracle && \
#     cp -r /opt/oracle/instantclient_*/* /opt/oracle/instantclient/ && \
#     rm -f /tmp/sqlplus.zip; \
#   else \
#     echo "Note: SQL*Plus not available for $ARCH architecture - SQLcl will be used as fallback"; \
#   fi

FROM node:20-bookworm-slim

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  curl \
  unzip \
  libaio1 \
  openjdk-17-jdk \
  ca-certificates \
  bash \
  iputils-ping \
  vim \
  nano \
  lsof \
  telnet \
  tcpdump \
  net-tools \
  htop \
  jq \
  openssl \
  git \
  && npm install -g nodemon \
  && rm -rf /var/lib/apt/lists/*

# Find and set Java home dynamically for both AMD64 and ARM64
RUN JAVA_HOME_CANDIDATE=$(find /usr/lib/jvm -name "java-17-openjdk*" -type d | head -1) && \
    echo "Found Java at: $JAVA_HOME_CANDIDATE" && \
    echo "export JAVA_HOME=$JAVA_HOME_CANDIDATE" >> /etc/environment && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/environment

# Set JAVA_HOME dynamically based on architecture
ENV JAVA_HOME_DYNAMIC=/usr/lib/jvm/java-17-openjdk-arm64
ENV CLASSPATH="/opt/oracle/sqlcl/lib/*"

# Pass build argument to runtime environment
ARG INSTALL_APEX
ENV INSTALL_APEX=${INSTALL_APEX}

COPY --from=demasylabs-builder package*.json ./
COPY --from=demasylabs-builder /usr/sandbox/app /usr/sandbox/app
COPY --from=demasylabs-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

# Set permissions for all scripts in runtime stage
RUN chmod +x /usr/sandbox/app/cli/*.sh && \
    chmod +x /usr/sandbox/app/system/utils/*.sh && \
    chmod +x /usr/sandbox/app/system/build/*.sh && \
    chmod +x /usr/sandbox/app/system/admin/*.sh && \
    chmod +x /usr/sandbox/app/system/download/*.sh && \
    chmod +x /usr/sandbox/app/system/install/*.sh && \
    chmod +x /usr/sandbox/app/oracle/admin/*.sh && \
    chmod +x /usr/sandbox/app/oracle/apex/*.sh && \
    chmod +x /usr/sandbox/app/oracle/mcp/*.sh && \
    chmod +x /usr/sandbox/app/oracle/sqlcl/*.sh && \
    chmod +x /usr/sandbox/app/oracle/sqlplus/*.sh

# Create a wrapper for SQLcl that detects Java path dynamically for any architecture
# Updated by demasy on November 11, 2025
# Enhanced to support both AMD64 and ARM64 architectures with dynamic Java detection
RUN echo '#!/bin/bash' > /usr/local/bin/sql && \
    echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH' >> /usr/local/bin/sql && \
    echo 'DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")' >> /usr/local/bin/sql && \
    echo 'export JAVA_HOME="$DETECTED_JAVA_HOME"' >> /usr/local/bin/sql && \
    echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> /usr/local/bin/sql && \
    echo 'cd /opt/oracle/sqlcl/bin && exec ./sql "$@"' >> /usr/local/bin/sql && \
    chmod +x /usr/local/bin/sql

# Symbolic links to Oracle tools and scripts


RUN ln -s /usr/sandbox/app/system/download/download.sh /usr/local/bin/download-oracle-components

# -------------------------------------------- [CLI Tools]
RUN ln -s /usr/sandbox/app/cli/sandbox.sh /usr/local/bin/sandbox
RUN ln -s /usr/sandbox/app/cli/commands.sh /usr/local/bin/commands
RUN ln -s /usr/sandbox/app/oracle/sqlplus/sqlplus-connect.sh /usr/local/bin/sqlplus
RUN ln -s /usr/sandbox/app/oracle/sqlcl/sqlcl-connect.sh /usr/local/bin/sqlcl
RUN ln -s /usr/sandbox/app/oracle/sqlcl/sqlcl-connect.sh /usr/local/bin/oracle

# -------------------------------------------- [Oracle APEX Tools]
# RUN ln -s /usr/sandbox/app/system/download/download-apex.sh /usr/local/bin/download-apex
# RUN ln -s /usr/sandbox/app/oracle/apex/install.sh /usr/local/bin/install-apex
# RUN ln -s /usr/sandbox/app/oracle/apex/uninstall.sh /usr/local/bin/uninstall-apex
# RUN ln -s /usr/sandbox/app/oracle/apex/start.sh /usr/local/bin/start-apex
# RUN ln -s /usr/sandbox/app/oracle/apex/stop.sh /usr/local/bin/stop-apex

# -------------------------------------------- [Software Install Tools]
# RUN ln -s /usr/sandbox/app/system/install/install-all.sh /usr/local/bin/install-all
# RUN ln -s /usr/sandbox/app/system/install/install-client.sh /usr/local/bin/install-client
# RUN ln -s /usr/sandbox/app/system/install/install-sqlplus.sh /usr/local/bin/install-sqlplus
# RUN ln -s /usr/sandbox/app/system/install/install-sqlcl.sh /usr/local/bin/install-sqlcl

# -------------------------------------------- [Admin & Diagnostics]
# RUN ln -s /usr/sandbox/app/system/admin/healthcheck.sh /usr/local/bin/healthcheck
RUN ln -s /usr/sandbox/app/oracle/admin/create-pdb.sh /usr/local/bin/create-pdb
RUN ln -s /usr/sandbox/app/oracle/admin/create-demasy-user.sh /usr/local/bin/create-demasy-user
RUN ln -s /usr/sandbox/app/oracle/admin/rollback-demasy-user.sh /usr/local/bin/rollback-demasy-user

# -------------------------------------------- [MCP Tools]
# RUN ln -s /usr/sandbox/app/oracle/mcp/start-mcp-with-saved-connection.sh /usr/local/bin/start-mcp


# Verify installation and test SQLcl
# Updated by demasy on November 11, 2025
# Enhanced verification to test both SQLcl and SQL*Plus installations
# RUN echo "Testing Java installation..." && \
#     java -version && \
#     DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::') && \
#     echo "Detected Java home: $DETECTED_JAVA_HOME" && \
#     echo "Testing SQLcl..." && \
#     cd /opt/oracle/sqlcl/bin && \
#     JAVA_HOME="$DETECTED_JAVA_HOME" ./sql -version && \
#     echo "Testing SQLPlus..." && \
#     (sqlplus -version || echo "SQLPlus not available - using Instant Client bundled version")

# Create MCP configuration directory
RUN mkdir -p /root/.mcp

EXPOSE 3000
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR /usr/sandbox/app

# Use startup script to handle initialization
CMD ["/usr/sandbox/app/system/build/startup.sh"]

