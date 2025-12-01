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
ENV SRC_ORACLE_SQLCL=$SRC_ORACLE_SQLCL
ENV SRC_ORACLE_SQLPLUS=$SRC_ORACLE_SQLPLUS
ENV SRC_ORACLE_APEX=$SRC_ORACLE_APEX
ENV SRC_ORACLE_ORDS=$SRC_ORACLE_ORDS
ARG SRC_ORACLE_INSTANTCLIENT
ENV SRC_ORACLE_INSTANTCLIENT=$SRC_ORACLE_INSTANTCLIENT

RUN mkdir -p /usr/demasy/app

COPY package*.json ./

WORKDIR /usr/demasy/app

COPY ./app.js ./app.js
# COPY ./src ./src
COPY ["LICENSE", "./"]

# Copy scripts to organized structure
COPY ./src/scripts/utils/*.sh /usr/demasy/scripts/utils/
COPY ./src/scripts/cli/sqlcl-connect.sh /usr/demasy/scripts/cli/sqlcl-connect.sh
COPY ./src/scripts/cli/sqlplus-connect.sh /usr/demasy/scripts/cli/sqlplus-connect.sh
COPY ./src/scripts/oracle/admin/healthcheck.sh /usr/demasy/scripts/oracle/admin/healthcheck.sh
COPY ./src/scripts/oracle/mcp/*.sh /usr/demasy/scripts/oracle/mcp/
COPY ./src/scripts/oracle/apex/*.sh /usr/demasy/scripts/oracle/apex/

# Set permissions for all scripts
RUN chmod +x /usr/demasy/scripts/utils/*.sh && \
    chmod +x /usr/demasy/scripts/cli/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/admin/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/mcp/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/apex/*.sh

WORKDIR /usr/demasy/scripts

# Download Oracle Instant Client (architecture-aware)
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
    IC_URL="https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.x64-23.7.0.24.10.zip"; \
  elif [ "$ARCH" = "aarch64" ]; then \
    IC_URL="https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.arm64-23.7.0.24.10.zip"; \
  else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
  fi && \
  echo "Downloading Instant Client for $ARCH from $IC_URL" && \
  curl -L -o /tmp/instantclient.zip "$IC_URL" && \
  unzip -qo /tmp/instantclient.zip -d /opt/oracle && \
  rm -f /tmp/instantclient.zip

# Download SQLcl
RUN curl -L -o /tmp/sqlcl.zip "$SRC_ORACLE_SQLCL" && \
  unzip -qo /tmp/sqlcl.zip -d /opt/oracle && \
  rm -f /tmp/sqlcl.zip

# Download APEX
RUN curl -L -o /tmp/apex.zip "$SRC_ORACLE_APEX" && \
  unzip -qo /tmp/apex.zip -d /opt/oracle && \
  rm -f /tmp/apex.zip

# Download ORDS
RUN curl -L -o /tmp/ords.zip "$SRC_ORACLE_ORDS" && \
  unzip -qo /tmp/ords.zip -d /opt/oracle/ords && \
  rm -f /tmp/ords.zip

# Download and install SQL*Plus
# Updated by demasy on November 11, 2025
# Added SQL*Plus support alongside SQLcl for enhanced Oracle client compatibility
# Note: Automatically detects architecture and provides appropriate solution
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
    curl -L -o /tmp/sqlplus.zip "$SRC_ORACLE_SQLPLUS" && \
    unzip -q /tmp/sqlplus.zip -d /opt/oracle && \
    cp -r /opt/oracle/instantclient_*/* /opt/oracle/instantclient/ && \
    rm -f /tmp/sqlplus.zip; \
  else \
    echo "Note: SQL*Plus not available for $ARCH architecture - SQLcl will be used as fallback"; \
  fi

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

COPY --from=demasylabs-builder package*.json ./
COPY --from=demasylabs-builder /usr/demasy /usr/demasy
COPY --from=demasylabs-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

# Set permissions for all scripts in runtime stage
RUN chmod +x /usr/demasy/scripts/utils/*.sh && \
    chmod +x /usr/demasy/scripts/cli/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/admin/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/mcp/*.sh && \
    chmod +x /usr/demasy/scripts/oracle/apex/*.sh

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
# -------------------------------------------- [CLI Tools]
RUN ln -s /usr/demasy/scripts/cli/sqlplus-connect.sh /usr/local/bin/sqlplus
RUN ln -s /usr/demasy/scripts/cli/sqlcl-connect.sh /usr/local/bin/sqlcl
RUN ln -s /usr/demasy/scripts/cli/sqlcl-connect.sh /usr/local/bin/oracle

# -------------------------------------------- [Oracle APEX Tools]
RUN ln -s /usr/demasy/scripts/oracle/apex/install.sh /usr/local/bin/install-apex
RUN ln -s /usr/demasy/scripts/oracle/apex/uninstall.sh /usr/local/bin/uninstall-apex
RUN ln -s /usr/demasy/scripts/oracle/apex/start.sh /usr/local/bin/start-apex
RUN ln -s /usr/demasy/scripts/oracle/apex/stop.sh /usr/local/bin/stop-apex

# # -------------------------------------------- [MCP Tools]
# RUN ln -s /usr/demasy/scripts/oracle/mcp/start.sh /usr/local/bin/start-mcp

# -------------------------------------------- [Admin & Diagnostics]
RUN ln -s /usr/demasy/scripts/oracle/admin/healthcheck.sh /usr/local/bin/healthcheck

# Verify installation and test SQLcl
# Updated by demasy on November 11, 2025
# Enhanced verification to test both SQLcl and SQL*Plus installations
RUN echo "Testing Java installation..." && \
    java -version && \
    DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::') && \
    echo "Detected Java home: $DETECTED_JAVA_HOME" && \
    echo "Testing SQLcl..." && \
    cd /opt/oracle/sqlcl/bin && \
    JAVA_HOME="$DETECTED_JAVA_HOME" ./sql -version && \
    echo "Testing SQLPlus..." && \
    (sqlplus -version || echo "SQLPlus not available - using Instant Client bundled version")

# Create MCP configuration directory
RUN mkdir -p /root/.mcp

EXPOSE 3000
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR /usr/demasy/app

CMD ["node", "app.js"]