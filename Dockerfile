# Stage 1: Build Stage
FROM node:20.19.4-slim AS demasylabs-builder

RUN apt-get update && \
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

RUN mkdir -p /usr/demasy/app

COPY package*.json ./

WORKDIR /usr/demasy/app

COPY ./app.js ./app.js
COPY ./src ./src
COPY ["LICENSE", "./"]

COPY ./libs/oracle/clients/instantclient_23_7 /opt/oracle/instantclient

RUN mkdir -p /usr/demasy/scripts && \
  curl -L -o /usr/demasy/scripts/connect.sh https://gist.githubusercontent.com/demasy/e913cdc3bf9897bc0374543d416d4d2d/raw/oracle-sqlcl-connect.sh && \
  chmod +x /usr/demasy/scripts/connect.sh

COPY ./src/scripts/diagnostics/healthcheck.sh /usr/demasy/admin/scripts/healthcheck.sh
COPY ./src/scripts/database/sqlplus-connect.sh /usr/demasy/scripts/sqlplus-connect.sh
COPY ./src/scripts/mcp /usr/demasy/scripts/mcp
COPY ./src/scripts/oracle/database/dev/apex /usr/demasy/scripts/apex

RUN chmod +x /usr/demasy/admin/scripts/healthcheck.sh
RUN chmod +x /usr/demasy/scripts/sqlplus-connect.sh
RUN chmod +x /usr/demasy/scripts/mcp/*.sh
RUN chmod +x /usr/demasy/scripts/apex/*.sh
# RUN chmod +x /usr/demasy/scripts/connect.sh

WORKDIR /usr/demasy/scripts

RUN curl -L -o sqlcl.zip "$SRC_ORACLE_SQLCL" && \
  unzip sqlcl.zip -d /opt/oracle && \
  rm sqlcl.zip

# Download APEX and ORDS
RUN curl -L -o apex.zip "$SRC_ORACLE_APEX" && \
  unzip apex.zip -d /opt/oracle && \
  rm apex.zip

RUN curl -L -o ords.zip "$SRC_ORACLE_ORDS" && \
  unzip ords.zip -d /opt/oracle/ords && \
  rm ords.zip

# Download and install SQL*Plus
# Updated by demasy on November 11, 2025
# Added SQL*Plus support alongside SQLcl for enhanced Oracle client compatibility
# Note: Automatically detects architecture and provides appropriate solution
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
    curl -L -o sqlplus.zip "$SRC_ORACLE_SQLPLUS" && \
    unzip sqlplus.zip -d /opt/oracle && \
    cp -r /opt/oracle/instantclient_*/* /opt/oracle/instantclient/ && \
    rm sqlplus.zip; \
  else \
    echo "Note: SQL*Plus not available for $ARCH architecture - SQLcl will be used as fallback"; \
  fi

FROM node:20.19.4-slim

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

RUN chmod +x /usr/demasy/scripts/connect.sh
RUN chmod +x /usr/demasy/scripts/sqlplus-connect.sh
RUN chmod +x /usr/demasy/admin/scripts/healthcheck.sh


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
# -------------------------------------------- [Oracle Database Tools]
RUN ln -s /usr/demasy/scripts/sqlplus-connect.sh /usr/local/bin/sqlplus
RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/sqlcl
RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/oracle
# -------------------------------------------- [MCP Tools]
RUN ln -s /usr/demasy/scripts/mcp/start-mcp-sqlcl.sh /usr/local/bin/start-mcp
# -------------------------------------------- [Oracle APEX Tools]
RUN ln -s /usr/demasy/scripts/apex/apex-install.sh /usr/local/bin/apex-install
RUN ln -s /usr/demasy/scripts/apex/apex-start.sh /usr/local/bin/apex-start
RUN ln -s /usr/demasy/scripts/apex/apex-stop.sh /usr/local/bin/apex-stop
RUN ln -s /usr/demasy/scripts/apex/apex-uninstall.sh /usr/local/bin/apex-uninstall
RUN ln -s /usr/demasy/scripts/apex/apex-install-internal.sh /usr/local/bin/install-apex


# -------------------------------------------- [Server scripts]
RUN ln -s /usr/demasy/admin/scripts/healthcheck.sh /usr/local/bin/healthcheck

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